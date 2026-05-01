output "sns_topic_arn" {
  value       = aws_sns_topic.log-alerts-topic.arn
  description = "ARN của SNS Topic để các Lambda function hoặc CloudWatch Alarms sử dụng"
}

output "sqs_queue_url" {
  value = aws_sqs_queue.log_queue.id
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.log_queue.arn
}