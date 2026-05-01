
# Cấp quyền
resource "aws_iam_role" "processor_role" {
  name = "processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "processor_policy" {
  name = "processor-policy"
  role = aws_iam_role.processor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Log hệ thống
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # SQS: Nên giới hạn ở ARN của Queue cụ thể
      {
        Effect   = "Allow"
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*" 
      },
      # DynamoDB: Quyền ghi log hàng loạt
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = "*"
      },
      # S3: Chỉ cho phép Put log vào đúng Bucket archive
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "*"
      },
      # SNS: Gửi Alert
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = "*" 
      }
    ]
  })
}
#Đóng gói
data "archive_file" "processor_zip" {
  type        = "zip"
  source_file = "processor.py"
  output_path = "processor.zip"
}
# Triển khai
resource "aws_lambda_function" "processor" {
  filename      = data.archive_file.processor_zip.output_path
  function_name = "gsvn-log-processor"
  role          = aws_iam_role.processor_role.arn
  handler       = "processor.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60  
  memory_size   = 256 

  source_code_hash = data.archive_file.processor_zip.output_base64sha256

  environment {
    variables = {
      TABLE_LOGS    = aws_dynamodb_table.app_logs.name
      TABLE_NOTI    = aws_dynamodb_table.noti_ttl.name
      BUCKET_NAME   = aws_s3_bucket.log_archive.id
      SNS_TOPIC_ARN = aws_sns_topic.log-alerts-topic.arn
    }
  }
}

