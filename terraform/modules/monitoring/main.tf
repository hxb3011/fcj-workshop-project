# Định nghĩa Log Group tập trung
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = var.log_group_name
  retention_in_days = var.retention_days
}

# Cấp quyền cho CloudWatch Logs gọi Lambda Shipper
resource "aws_lambda_permission" "allow_cloudwatch_shipper" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.shipper_lambda_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.app_logs.arn}:*"
}

# Bộ lọc đăng ký để đẩy log sang Shipper
resource "aws_cloudwatch_log_subscription_filter" "log_to_shipper" {
  name            = "${var.project_name}_log_to_shipper_filter"
  log_group_name  = aws_cloudwatch_log_group.app_logs.name
  filter_pattern  = var.filter_pattern
  destination_arn = var.shipper_lambda_arn
  depends_on      = [aws_lambda_permission.allow_cloudwatch_shipper]
}