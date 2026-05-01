# 1. Tạo Role riêng cho Lambda Getter
resource "aws_iam_role" "getter_role" {
  name = "getter_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 2. Chính sách quyền hạn (Policy) cho Role Getter
resource "aws_iam_role_policy" "getter_policy" {
  name = "getter_policy"
  role = aws_iam_role.getter_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadHotLogsFromDynamoDB"
        Action   = ["dynamodb:Query", "dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:*:*:table/AppLogs"
      },
      {
        Sid      = "ExecuteAthenaQueries"
        Action   = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "glue:GetTable",
          "glue:GetDatabase"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid      = "S3Access"
        Action   = ["s3:Get*", "s3:List*", "s3:PutObject"]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::fcaj-log-archive-project/*",
          "arn:aws:s3:::fcaj-athena-queries-project-output/*",
          "arn:aws:s3:::fcaj-athena-queries-project-output"
        ]
      },
      {
        Sid      = "Logging"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# 3. Cấu hình Workgroup cho Athena
resource "aws_athena_workgroup" "log_project_workgroup" {
  name = "log_project_workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}