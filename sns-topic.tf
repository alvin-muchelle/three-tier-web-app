# 1. Create the SNS Topic

resource "aws_sns_topic" "login_topic" {
  name = "login-details-topic"
}

# 2. SNS Topic Subscription

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.login_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
