# Create SNS topic for bounce messages
resource "aws_sns_topic" "bounce_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${var.instance_id}-bounce"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "bounce" {
  count = (var.enable_feedback_notifications ? 1 : 0)

  configuration_set_name = aws_sesv2_configuration_set.config.configuration_set_name
  event_destination_name = "${var.instance_id}-bounce"

  event_destination {
    # Valid types: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set_event_destination#matching_event_types
    matching_event_types = ["BOUNCE"]
    sns_destination {
      topic_arn = aws_sns_topic.bounce_topic[0].arn
    }
  }
}

# Create SNS topic for complaint messages
resource "aws_sns_topic" "complaint_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${var.instance_id}-complaint"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "name" {
  count = (var.enable_feedback_notifications ? 1 : 0)

  configuration_set_name = aws_sesv2_configuration_set.config.configuration_set_name
  event_destination_name = "${var.instance_id}-complaint"
  event_destination {
    matching_event_types = ["COMPLAINT"]
    sns_destination {
      topic_arn = aws_sns_topic.complaint_topic[0].arn
    }
  }
}

# Create SNS topic for delivery messages
resource "aws_sns_topic" "delivery_topic" {
  count = (var.enable_feedback_notifications ? 1 : 0)
  name  = "${var.instance_id}-delivery"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "delivery" {
  count = (var.enable_feedback_notifications ? 1 : 0)

  configuration_set_name = aws_sesv2_configuration_set.config.configuration_set_name
  event_destination_name = "${var.instance_id}-delivery" # todo, what is this used for?
  event_destination {
    matching_event_types = ["DELIVERY"]
    sns_destination {
      topic_arn = aws_sns_topic.delivery_topic[0].arn
    }
  }
  # include_original_headers = true # todo: This was on the v1 resource.
}
