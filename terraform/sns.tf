resource "aws_sns_topic" "log-alerts-topic" {
  name = "log-alerts-topic"
}

output "sns_topic_arn" {
  value = aws_sns_topic.log-alerts-topic.arn
}