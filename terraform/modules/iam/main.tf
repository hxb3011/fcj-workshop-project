# 1. ECS Execution Role (Quyền của bản thân dịch vụ ECS)
resource "aws_iam_role" "execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach policy chuẩn của AWS để ECS có thể kéo image và đẩy log
resource "aws_iam_role_policy_attachment" "execution_attach" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. ECS Task Role (Quyền của ứng dụng FastAPI chạy bên trong)
resource "aws_iam_role" "task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Policy tùy chỉnh cho logic đăng ký App của bạn
resource "aws_iam_role_policy" "task_policy" {
  name = "${var.project_name}-task-policy"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["cognito-idp:AdminCreateUser", "cognito-idp:AdminSetUserPassword"]
        Resource = [var.user_pool_arn]
      },
      {
        Effect   = "Allow"
        Action   = [
          "iam:CreateUser", 
          "iam:CreateAccessKey", 
          "iam:AttachUserPolicy", 
          "iam:PutUserPolicy"
        ]
        Resource = ["arn:aws:iam::*:user/app_*"]
      },
      {
        
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem"]
        Resource = [var.app_clients_table_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Subscribe"]
        Resource = [var.sns_topic_arn]
      }
    ]
  })
}
#=================================================

# 1. Tạo Trust Policy cho phép EC2 đảm nhận Role này
resource "aws_iam_role" "monitor_app_role" {
  name = "${var.project_name}-monitor-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Tạo Policy chi tiết cho các dịch vụ app cần sử dụng
resource "aws_iam_policy" "monitor_app_policy" {
  name        = "${var.project_name}-monitor-app-policy"
  description = "Quyen truy cap DynamoDB, Athena, S3 cho Monitor App"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Quyền cho DynamoDB (Hot Storage)
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [var.dynamodb_app_logs_arn]
      },
      # Quyền cho Athena & Glue (Cold Storage)
      {
        Effect   = "Allow"
        Action   = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution",
          "glue:GetTable",
          "glue:GetDatabase",
          "glue:GetPartitions"
        ]
        Resource = ["*"] # Athena/Glue cần access rộng hơn để query metadata
      },
      # Quyền cho S3 (Archive logs và Athena Results)
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          var.log_archive_bucket_arn,
          "${var.log_archive_bucket_arn}/*",
          var.athena_results_bucket_arn,
          "${var.athena_results_bucket_arn}/*"
        ]
      },
      # Quyền cho Cognito (Xác thực login tại Backend)
      {
        Effect   = "Allow"
        Action   = [
          "cognito-idp:InitiateAuth",
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:GetUser"
        ]
        Resource = [var.user_pool_arn]
      }
    ]
  })
}

# 3. Gắn Policy vào Role
resource "aws_iam_role_policy_attachment" "attach_monitor_policy" {
  role       = aws_iam_role.monitor_app_role.name
  policy_arn = aws_iam_policy.monitor_app_policy.arn
}

# 4. Tạo Instance Profile (Đây là cái chúng ta truyền vào EC2)
resource "aws_iam_instance_profile" "monitor_app_profile" {
  name = "${var.project_name}-monitor-app-profile"
  role = aws_iam_role.monitor_app_role.name
}