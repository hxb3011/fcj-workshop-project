# 1. IAM Role cho Lambda Getter
resource "aws_iam_role" "getter_role" {
  name = "${var.project_name}-getter-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 2. IAM Policy cho Getter (Query DynamoDB + Athena + S3)
resource "aws_iam_role_policy" "getter_policy" {
  name = "${var.project_name}-getter-policy"
  role = aws_iam_role.getter_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadHotLogsFromDynamoDB"
        Action   = ["dynamodb:Query", "dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = [var.dynamodb_app_logs_arn]
      },
      {
        Sid      = "ExecuteAthenaQueries"
        Action   = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "glue:GetTable",
          "glue:GetDatabase",
          "glue:GetPartitions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid      = "S3Access"
        Action   = [
          "s3:Get*", 
          "s3:List*", 
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Effect   = "Allow"
        Resource = [
          var.log_archive_bucket_arn,
          "${var.log_archive_bucket_arn}/*",
          var.athena_results_bucket_arn,
          "${var.athena_results_bucket_arn}/*"
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
  name          = "${var.project_name}-workgroup"
  force_destroy = true 

  configuration {
    result_configuration {
      output_location = "s3://${var.athena_results_bucket_name}/"
    }
  }
}