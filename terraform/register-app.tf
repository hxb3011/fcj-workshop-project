resource "aws_iam_policy" "register_app_policy" {
  name        = "register-app-policy"
  description = "Quyền cho Server để quản lý App Registration và IAM Users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DynamoDBAccess"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem"]
        Resource = "*"
      },
      {
        Sid      = "SNSSubscribeAccess"
        Effect   = "Allow"
        Action   = ["sns:Subscribe"]
        Resource = "*"
      },
      {
        Sid      = "IAMManagement"
        Effect   = "Allow"
        Action   = [
          "iam:CreateUser",
          "iam:AttachUserPolicy",
          "iam:CreateAccessKey"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role" "register_app_role" {
  name = "register-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_register_policy" {
  role       = aws_iam_role.register_app_role.name
  policy_arn = aws_iam_policy.register_app_policy.arn
}

resource "aws_iam_policy" "app_client_logs_policy" {
  name        = "app-client-logs-policy"
  description = "Cho phép App tạo và gửi log vào CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}
