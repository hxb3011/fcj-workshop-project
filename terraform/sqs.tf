resource "aws_sqs_queue" "log_queue" {
  name                        = "LogQueue"
  
  fifo_queue                  = false
  
  content_based_deduplication = false

  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 360 
}
resource "aws_lambda_event_source_mapping" "sqs_to_processor" {
  event_source_arn = aws_sqs_queue.log_queue.arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 10  
  enabled          = true
}