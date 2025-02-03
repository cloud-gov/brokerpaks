output "region" {
  value = var.aws_region_govcloud
}

output "required_records" {
  value = local.manage_domain ? null : local.required_records_as_string
}

output "dmarc_report_uri_aggregate" {
  value = var.dmarc_report_uri_aggregate
}

output "dmarc_report_uri_failure" {
  value = var.dmarc_report_uri_failure
}

output "instructions" {
  value = local.instructions
}

output "configuration_set_arn" {
  value = aws_sesv2_configuration_set.config.arn
}

output "domain_arn" {
  value = aws_sesv2_email_identity.identity.arn
}

output "reputation_topic_arn" {
  value = aws_sns_topic.ses_reputation_notifications
}

output "bounce_topic_arn" {
  value = local.bounce_topic_sns_arn
}

output "complaint_topic_arn" {
  value = local.complaint_topic_sns_arn
}

output "delivery_topic_arn" {
  value = local.delivery_topic_sns_arn
}
