locals {
  instance_sha = "ses-${substr(sha256(var.instance_id), 0, 16)}"

  # If no domain was provided, we create and manage one instead.
  manage_domain = (var.domain == "")
  domain        = (local.manage_domain ? "${local.instance_sha}.${var.default_domain}" : var.domain)

  dmarc_verification_record = {
    name = "_dmarc.${local.domain}"
    type = "TXT"
    ttl  = "600"
    // rua=mailto:reports@dmarc.cyber.dhs.gov and p=reject are required by BOD-18-01: https://cyber.dhs.gov/assets/report/bod-18-01.pdf
    records = ["v=DMARC1; p=reject; rua=mailto:reports@dmarc.cyber.dhs.gov, ${var.dmarc_report_uri_aggregate}; ruf=mailto:${var.dmarc_report_uri_failure}"]
  }

  setting_mail_from = (var.mail_from_subdomain != "")
  mail_from_domain  = "${var.mail_from_subdomain}.${aws_sesv2_email_identity.identity.email_identity}"

  mx_verification_record = {
    name    = local.mail_from_domain
    type    = "MX"
    ttl     = "600"
    records = ["10 feedback-smtp.${var.aws_region_govcloud}.amazonses.com"]
  }

  spf_verification_record = {
    name    = (local.setting_mail_from ? local.mail_from_domain : local.domain)
    type    = "TXT"
    ttl     = "600"
    records = ["v=spf1 include:amazonses.com -all"]
  }

  dkim_records = [for i, token in aws_sesv2_email_identity.identity.dkim_signing_attributes[0].tokens :
    {
      name    = "${token}._domainkey.${local.domain}"
      type    = "CNAME"
      ttl     = "600"
      records = ["${token}.dkim.amazonses.com"]
    }
  ]

  required_records = {
    dmarc_verification_record = local.dmarc_verification_record
    spf_verification_record   = local.spf_verification_record
    dkim_record_0             = local.dkim_records[0]
    dkim_record_1             = local.dkim_records[1]
    dkim_record_2             = local.dkim_records[2]
  }

  # Generate string output usable for pasting into HCL elsewhere if needed
  required_records_as_string = <<-EOT

  {%{for key, value in local.required_records}
    ${key} = {
      name    = "${value.name}"
      type    = "${value.type}"
      ttl     = "${value.ttl}"
      records = [%{for record in value.records}"${record}"%{endfor~}]
    } %{endfor}
    %{if local.setting_mail_from}mx_verification_record = {
      name    = "${local.mx_verification_record.name}"
      type    = "${local.mx_verification_record.type}"
      ttl     = "${local.mx_verification_record.ttl}"
      records = [%{for record in local.mx_verification_record.records}"${record}"%{endfor~}]
    } %{endif}
  }
  EOT

  # If no domain was specified, we manage the generated domain and need to
  # create the records ourselves
  required_records_flatter = {
    for key, value in local.required_records :
    key => {
      id     = key
      name   = value.name
      type   = value.type
      ttl    = value.ttl
      record = value.records[0]
    }
  }

  route53_records = (local.manage_domain ? local.required_records_flatter : {})

  # SNS topic locals
  bounce_topic_sns_arn    = (var.enable_feedback_notifications ? aws_sns_topic.bounce_topic[0].arn : "")
  complaint_topic_sns_arn = (var.enable_feedback_notifications ? aws_sns_topic.complaint_topic[0].arn : "")
  delivery_topic_sns_arn  = (var.enable_feedback_notifications ? aws_sns_topic.delivery_topic[0].arn : "")

  instructions = (local.manage_domain ? null : "Your SMTP service was provisioned, but is not yet verified. To verify your control of the ${var.domain} domain, create the 'required_records' provided here in the ${var.domain} zone before using the service.")
}

resource "aws_sesv2_email_identity" "identity" {
  configuration_set_name = aws_sesv2_configuration_set.config.configuration_set_name
  email_identity         = local.domain

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_email_identity_mail_from_attributes" "mail_from" {
  count = (local.setting_mail_from ? 1 : 0)

  email_identity   = aws_sesv2_email_identity.identity.email_identity
  mail_from_domain = local.mail_from_domain

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_configuration_set" "config" {
  configuration_set_name = "${var.instance_id}-config"

  delivery_options {
    tls_policy = "REQUIRE"
  }
  reputation_options {
    reputation_metrics_enabled = true
  }
  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }

  lifecycle {
    prevent_destroy = true

    # The csb-helper will disable sending on an identity if its reputation
    # metrics exceed a certain threshold. To avoid the CSB accidentally
    # overwriting this change, ignore changes to the sending_enabled field.
    ignore_changes = [sending_options["sending_enabled"]]
  }
}
