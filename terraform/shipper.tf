# Shipper 
# IAM shipper
resource "aws_iam_role" "shipper_role" {
  name = "shipper-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "shipper_policy" {
  name = "shipper-policy"
  role = aws_iam_role.shipper_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*" #
      }
    ]
  })
}
#Đóng gói
data "archive_file" "shipper_zip" {
  type        = "zip"
  source_file = "shipper.py"
  output_path = "shipper.zip"
}
resource "aws_lambda_function" "shipper" {
  filename      = data.archive_file.shipper_zip.output_path
  function_name = "shipper"
  role          = aws_iam_role.shipper_role.arn
  handler       = "shipper.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  source_code_hash = data.archive_file.shipper_zip.output_base64sha256

  environment {
    variables = {
      SQS_URL = aws_sqs_queue.log_queue.id
    }
  }
}