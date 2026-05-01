resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/app/log-project"
  retention_in_days = 7
}
resource "aws_lambda_permission" "allow_cloudwatch_shipper" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shipper.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.app_logs.arn}:*"
}
resource "aws_cloudwatch_log_subscription_filter" "log_to_shipper" {
  name            = "gsvn_log_to_shipper_filter"
  log_group_name  = aws_cloudwatch_log_group.app_logs.name
  filter_pattern  = "" 
  destination_arn = aws_lambda_function.shipper.arn
  depends_on      = [aws_lambda_permission.allow_cloudwatch_shipper]
}