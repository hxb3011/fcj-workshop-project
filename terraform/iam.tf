resource "aws_iam_role" "log_project_role" {
  name = "lambda_ses_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "log_project_policy" {
  name = "log_project_policy"
  role = aws_iam_role.log_project_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CloudWatchLogsAccess"
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Sid      = "DynamoDBAccess"
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ]
        Resource = [
          "arn:aws:dynamodb:*:*:table/AppLogs",
          "arn:aws:dynamodb:*:*:table/AppClients",
          "arn:aws:dynamodb:*:*:table/NotiTTL"
        ]
      },
      {
        Sid      = "S3FullAccessForAthena"
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          "arn:aws:s3:::fcaj-log-archive",
          "arn:aws:s3:::fcaj-log-archive/*",
          "arn:aws:s3:::fcaj-athena-queries-output",
          "arn:aws:s3:::fcaj-athena-queries-output/*"
        ]
      },
      {
        Sid      = "AthenaAndGlueAccess"
        Effect   = "Allow"
        Action   = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution",
          "athena:GetWorkGroup",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:GetDatabase",
          "glue:GetTables"
        ]
        Resource = "*"
      },
      {
        Sid      = "SQSAndSNSAccess"
        Effect   = "Allow"
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sns:Publish",
          "sns:Subscribe",
          "sns:GetTopicAttributes"
        ]
        Resource = "*"
      }
    ]
  })
}