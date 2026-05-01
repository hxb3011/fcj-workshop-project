resource "aws_sns_topic" "log-alerts-topic" {
  name = "${var.project_name}-log-alerts-topic"
}

resource "aws_sqs_queue" "log_queue" {
  name                        = "${var.project_name}-log-queue"
  
  fifo_queue                  = false
  
  content_based_deduplication = false

  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 360
}