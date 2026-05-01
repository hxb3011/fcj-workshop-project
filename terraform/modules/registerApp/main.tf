
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}


resource "aws_cloudwatch_log_group" "ecs_log" {
  name              = "/ecs/${var.project_name}-register-app"
  retention_in_days = 1
}


resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-register-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "register-app-container"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]
      environment = [
        { name = "USER_POOL_ID", value = var.user_pool_id },
        { name = "APP_CLIENTS_TABLE", value = var.table_name },
        { name = "SNS_TOPIC_ARN", value = var.sns_topic_arn },
        { name = "LOG_POLICY_ARN", value = var.log_policy_arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Service duy trì trạng thái chạy của container
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = true 
  }
}