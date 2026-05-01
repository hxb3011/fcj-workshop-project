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