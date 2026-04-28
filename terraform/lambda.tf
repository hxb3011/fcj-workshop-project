# Lambda 1: Đăng ký Email
resource "aws_lambda_function" "subscribe_lambda" {
  filename      = "subscribe.zip"
  function_name = "SNS_Register_Email"
  role          = aws_iam_role.log_project_role.arn
  handler       = "subscribe.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = { SNS_TOPIC_ARN = aws_sns_topic.log-alerts-topic.arn }
  }
}

# Test Case 1: Đăng ký thành công
resource "aws_schemas_schema" "test_sub_success" {
  name          = "_${aws_lambda_function.subscribe_lambda.function_name}-Success"
  registry_name = "lambda-testevent-schemas"
  type          = "JSONSchemaDraft4"
  content       = jsonencode({
    "body": "{\"appId\": \"1\", \"email\": \"trangiabao16082003@gmail.com\"}"
  })
}

# Test Case 2: Thiếu dữ liệu
resource "aws_schemas_schema" "test_sub_missing" {
  name          = "_${aws_lambda_function.subscribe_lambda.function_name}-MissingField"
  registry_name = "lambda-testevent-schemas"
  type          = "JSONSchemaDraft4"
  content       = jsonencode({
    "body": "{\"appId\": \"1\"}" # Thiếu email
  })
}



# Lambda 2: Gửi tin nhắn (Message)
resource "aws_lambda_function" "publish_lambda" {
  filename      = "publish.zip"
  function_name = "SNS_Send_Message"
  role          = aws_iam_role.log_project_role.arn
  handler       = "publish.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = { SNS_TOPIC_ARN = aws_sns_topic.log-alerts-topic.arn }
  }
}
# Test Case 1: Gửi cảnh báo chuẩn
resource "aws_schemas_schema" "test_pub_success" {
  name          = "_${aws_lambda_function.publish_lambda.function_name}-ValidAlert"
  registry_name = "lambda-testevent-schemas"
  type          = "JSONSchemaDraft4"
  content       = jsonencode({
    "appId": "1",
    "appName": "Accounting System",
    "subject": "Payment Error",
    "message": "Transaction #12345 failed to process."
  })
}