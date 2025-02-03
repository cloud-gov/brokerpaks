# Create SNS topic for reputation alarms. Always create, regardless of var.enable_feedback_notifications.
resource "aws_sns_topic" "ses_reputation_notifications" {
  name = "${var.instance_id}-ses-reputation-notifications"

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  # Notify the Cloud.gov Platform team and the customer.
  reputation_notification_topics = [
    var.cloud_gov_email_notification_topic_arn,
    var.cloud_gov_slack_notification_topic_arn,
    aws_sns_topic.ses_reputation_notifications.arn
  ]
}

/*
An AWS account is placed under review if its bounce rate is ≥5%. Sending is automatically paused if its bounce rate is ≥10%. For each individual identity, we send a warning alarm at 40% of the review threshold and a critical alarm at 80% of the review threshold. This provides early warning and margin for error.

https://docs.aws.amazon.com/ses/latest/dg/reputationdashboardmessages.html#reputationdashboard-bounce
*/

# 5% * 40% = 2%. 5% * 80% = 4%.
resource "aws_cloudwatch_metric_alarm" "ses_bounce_rate_warning" {
  alarm_name        = "SES-BounceRate-Warning-Identity-${aws_sesv2_email_identity.identity.email_identity}"
  alarm_description = <<EOT
  Warning: The bounce rate for this SES identity has exceeded 2%. To protect our organizational reputation metrics, at 4%, Cloud.gov will pause your ability to send mail from this identity. For information about specific email bounces, check this identity's bounce notification topic. (Create one by updating the service instance if you have not already.) See https://services.cloud.gov for more information about the SES service offering, and see AWS documentation for more information about reputation metrics: https://docs.aws.amazon.com/ses/latest/dg/reputationdashboardmessages.html#reputationdashboard-bounce. You can reach Cloud.gov support at support@cloud.gov.

  - SES identity: ${aws_sesv2_email_identity.identity.email_identity}
  - CF service instance GUID: ${var.instance_id}
  - CF organization GUID: ${local.organization_guid}
  - CF organization name: ${local.organization_name}
  - CF space GUID: ${local.space_guid}
  - CF space name: ${local.space_name}
  EOT

  dimensions = {
    "ConfigurationSetName" = aws_sesv2_configuration_set.config.configuration_set_name
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "BounceRate"
      namespace   = "AWS/SES"
      period      = 300
      stat        = "Average"
    }
    return_data = false
  }

  metric_query {
    id          = "warning_e1"
    expression  = "IF(m1 >= 0.02 && m1 < 0.04, 1, 0)"
    label       = "BounceRateBetween1and5"
    return_data = true
  }

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 1
  evaluation_periods        = 1
  alarm_actions             = local.reputation_notification_topics
  ok_actions                = local.reputation_notification_topics
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "ses_bounce_rate_critical" {
  alarm_name        = "SES-BounceRate-Critical-Identity-${aws_sesv2_email_identity.identity.email_identity}"
  alarm_description = <<EOT
  Critical: The bounce rate for this SES identity has exceeded 4%. To protect our organizational reputation metrics, Cloud.gov will pause your ability to send mail from this identity. For information about specific email bounces, check this identity's bounce notification topic. (Create one by updating the service instance if you have not already.) See https://services.cloud.gov for more information about the SES service offering, and see AWS documentation for more information about reputation metrics: https://docs.aws.amazon.com/ses/latest/dg/reputationdashboardmessages.html#reputationdashboard-bounce. You can reach Cloud.gov support at support@cloud.gov.

  - SES identity: ${aws_sesv2_email_identity.identity.email_identity}
  - CF service instance GUID: ${var.instance_id}
  - CF organization GUID: ${local.organization_guid}
  - CF organization name: ${local.organization_name}
  - CF space GUID: ${local.space_guid}
  - CF space name: ${local.space_name}
  EOT

  dimensions = {
    "ConfigurationSetName" = aws_sesv2_configuration_set.config.configuration_set_name
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "BounceRate"
      namespace   = "AWS/SES"
      period      = 300
      stat        = "Average"
    }
    return_data = false
  }

  metric_query {
    id          = "critical_e1"
    expression  = "IF(m1 >= 0.04, 1, 0)"
    label       = "BounceRateAbove5"
    return_data = true
  }

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 1
  evaluation_periods        = 1
  alarm_actions             = local.reputation_notification_topics
  ok_actions                = local.reputation_notification_topics
  insufficient_data_actions = []
}

/*
An AWS account is placed under review if its complaint rate is ≥0.1%. Sending is automatically paused if its complaint rate is ≥0.5%. For each individual identity, we send a warning alarm at 40% of the review threshold and a critical alarm at 80% of the review threshold. This provides early warning and margin for error.

https://docs.aws.amazon.com/ses/latest/dg/reputationdashboardmessages.html#reputationdashboard-complaint
*/

# 0.1% * 40% = 0.04%. 0.01% * 80% = 0.08%.
resource "aws_cloudwatch_metric_alarm" "ses_complaint_rate_warning" {
  alarm_name        = "SES-ComplaintRate-Warning-Identity-${aws_sesv2_email_identity.identity.email_identity}"
  alarm_description = <<EOT
  Warning: The complaint rate for this SES identity has exceeded 0.04%. To protect our organizational reputation metrics, at 0.08%, Cloud.gov will pause your ability to send mail from this identity. For information about specific email complaints, check this identity's complaint notification topic. (Create one by updating the service instance if you have not already.) See https://services.cloud.gov for more information about the SES service offering, and see AWS documentation for more information about reputation metrics: https://docs.aws.amazon.com/ses/latest/dg/reputationdashboardmessages.html#reputationdashboard-complaint. You can reach Cloud.gov support at support@cloud.gov.

  - SES identity: ${aws_sesv2_email_identity.identity.email_identity}
  - CF service instance GUID: ${var.instance_id}
  - CF organization GUID: ${local.organization_guid}
  - CF organization name: ${local.organization_name}
  - CF space GUID: ${local.space_guid}
  - CF space name: ${local.space_name}
  EOT

  dimensions = {
    "ConfigurationSetName" = aws_sesv2_configuration_set.config.configuration_set_name
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "ComplaintRate"
      namespace   = "AWS/SES"
      period      = 300
      stat        = "Average"
    }
    return_data = false
  }

  metric_query {
    id          = "warning_e1"
    expression  = "IF(m1 >= 0.0004 && m1 < 0.0008, 1, 0)"
    label       = "ComplaintRateBetween0.02and0.08"
    return_data = true
  }

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 1
  evaluation_periods        = 1
  alarm_actions             = local.reputation_notification_topics
  ok_actions                = local.reputation_notification_topics
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "ses_complaint_rate_critical" {
  alarm_name        = "SES-ComplaintRate-Critical-Identity-${aws_sesv2_email_identity.identity.email_identity}"
  alarm_description = <<EOT
  Critical: The complaint rate for this SES identity has exceeded 0.08%. To protect our organizational reputation metrics, Cloud.gov will pause your ability to send mail from this identity. For information about specific email complaints, check this identity's complaint notification topic. (Create one by updating the service instance if you have not already.) See https://services.cloud.gov for more information about the SES service offering, and see AWS documentation for more information about reputation metrics: https://docs.aws.amazon.com/ses/latest/dg/reputationdashboardmessages.html#reputationdashboard-complaint. You can reach Cloud.gov support at support@cloud.gov.

  - SES identity: ${aws_sesv2_email_identity.identity.email_identity}
  - CF service instance GUID: ${var.instance_id}
  - CF organization GUID: ${local.organization_guid}
  - CF organization name: ${local.organization_name}
  - CF space GUID: ${local.space_guid}
  - CF space name: ${local.space_name}
  EOT

  dimensions = {
    "ConfigurationSetName" = aws_sesv2_configuration_set.config.configuration_set_name
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "ComplaintRate"
      namespace   = "AWS/SES"
      period      = 300
      stat        = "Average"
    }
    return_data = false
  }

  metric_query {
    id          = "critical_e1"
    expression  = "IF(m1 >= 0.0008, 1, 0)"
    label       = "ComplaintRateAbove0.08"
    return_data = true
  }

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 1
  evaluation_periods        = 1
  alarm_actions             = local.reputation_notification_topics
  ok_actions                = local.reputation_notification_topics
  insufficient_data_actions = []
}
