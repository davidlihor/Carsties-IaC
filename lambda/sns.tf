resource "aws_sns_topic" "compliance_topic" {
  name = "compliance-lambda-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.compliance_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}