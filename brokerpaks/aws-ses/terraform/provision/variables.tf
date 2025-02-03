// Provider credentials
variable "aws_access_key_id_govcloud" {
  type = string
}

variable "aws_secret_access_key_govcloud" {
  type      = string
  sensitive = true
}

variable "aws_region_govcloud" {
  type = string
}

variable "aws_access_key_id_commercial" {
  type = string
}

variable "aws_secret_access_key_commercial" {
  type      = string
  sensitive = true
}

variable "aws_region_commercial" {
  type = string
}

// Brokerpak configuration
variable "domain" {
  type        = string
  description = "Domain from mail will be sent. For example, agency.gov. If left empty, a temporary cloud.gov subdomain will be generated."
  default     = ""
}

variable "default_domain" {
  type        = string
  description = "Computed. Fallback domain to use if none was supplied."
}

variable "instance_id" {
  type        = string
  default     = ""
  description = "The identifier for the instance, which together with the Plan ID and Service ID is unique. When CAPI sends the provision request, this is a GUID."
}

variable "dmarc_report_uri_aggregate" {
  type        = string
  description = "The mailto URI to which DMARC aggregate reports should be sent. For example, 'mailto:dmarc@example.gov'."
}

variable "dmarc_report_uri_failure" {
  type        = string
  description = "To mailto URI to which to which DMARC individual message failure reports should be sent. For example, 'mailto:dmarc@example.gov'."
}

variable "labels" {
  type    = map(any)
  default = {}
}

variable "enable_feedback_notifications" {
  type        = bool
  description = "Toggle whether to create SNS topics for feedback notifications"
  default     = false
}

variable "mail_from_subdomain" {
  type        = string
  description = "Subdomain to set as the mail-from value"
  default     = ""
}

variable "context" {
  type        = any
  description = "Cloud Foundry context object from provision call. Useful for tagging resources."
}

variable "service_offering_name" {
  type        = string
  description = "Name of the Cloud Foundry service offering. Used for tagging."
}

variable "service_plan_name" {
  type        = string
  description = "Name of the Cloud Foundry service plan. Used for tagging."
}

variable "cloud_gov_environment" {
  type        = string
  description = "The cloud.gov environment the broker is deployed in. For example: local, development, staging, or production."
}

variable "cloud_gov_email_notification_topic_arn" {
  type        = string
  description = "SNS topic ARN. Reputation notifications are sent to the Cloud.gov team for awareness."
}

variable "cloud_gov_slack_notification_topic_arn" {
  type        = string
  description = "SNS topic ARN. Reputation notifications are sent to the Cloud.gov team for awareness."
}
