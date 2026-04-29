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



# Lambda 3: Xử lý Log 
resource "aws_lambda_function" "log_processor" {
  filename      = "processor.zip"
  function_name = "LogProcessor"
  role          = aws_iam_role.log_project_role.arn
  handler       = "processor.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.log-alerts-topic.arn
    }
  }
}

# Kết nối SQS FIFO làm Trigger cho Lambda
resource "aws_lambda_event_source_mapping" "sqs_fifo_trigger" {
  event_source_arn = aws_sqs_queue.log_queue_fifo.arn 
  function_name    = aws_lambda_function.log_processor.arn
  batch_size       = 10 
}

# Test Case 1: Lỗi hệ thống (Gửi Email)
resource "aws_schemas_schema" "test_processor_error" {
  name          = "_${aws_lambda_function.log_processor.function_name}-ErrorAlert"
  registry_name = "lambda-testevent-schemas"
  type          = "JSONSchemaDraft4"
  content       = jsonencode({
    "Records": [
      {
        "body": "{\"appId\": \"FCAJ_Backend\", \"level\": \"ERROR\", \"message\": \"Database FIFO connection failed\"}"
      }
    ]
  })
}

# Test Case 2: Thông tin bình thường (Chỉ lưu trữ)
resource "aws_schemas_schema" "test_processor_info" {
  name          = "_${aws_lambda_function.log_processor.function_name}-InfoLog"
  registry_name = "lambda-testevent-schemas"
  type          = "JSONSchemaDraft4"
  content       = jsonencode({
    "Records": [
      {
        "body": "{\"appId\": \"FCAJ_Frontend\", \"level\": \"INFO\", \"message\": \"User session preserved in FIFO\"}"
      }
    ]
  })
}