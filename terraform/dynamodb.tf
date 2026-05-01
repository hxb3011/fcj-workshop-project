# Định nghĩa các bảng DynamoDB để lưu trữ thông tin về ứng dụng, log và TTL cho thông báo
resource "aws_dynamodb_table" "app_clients" {
  name           = "AppClients"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "appId"

  attribute {
    name = "appId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "app_logs" {
  name           = "AppLogs"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "appId"
  range_key      = "timestamp"

  attribute {
    name = "appId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }
}

resource "aws_dynamodb_table" "noti_ttl" {
  name           = "NotiTTL"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "appId"

  attribute {
    name = "appId"
    type = "S"
  }

  ttl {
    attribute_name = "expireAt"
    enabled        = true
  }
}


output "dynamodb_app_clients_name" {
  description = "Tên bảng lưu trữ thông tin đăng ký ứng dụng"
  value       = aws_dynamodb_table.app_clients.name
}

output "dynamodb_app_logs_name" {
  description = "Tên bảng lưu trữ log (Hot Storage)"
  value       = aws_dynamodb_table.app_logs.name
}

output "dynamodb_noti_ttl_name" {
  description = "Tên bảng kiểm soát tần suất gửi thông báo (Anti-spam)"
  value       = aws_dynamodb_table.noti_ttl.name
}

output "dynamodb_all_table_arns" {
  description = "Danh sách ARN của tất cả các bảng DynamoDB"
  value = [
    aws_dynamodb_table.app_clients.arn,
    aws_dynamodb_table.app_logs.arn,
    aws_dynamodb_table.noti_ttl.arn
  ]
}