output "app_clients_arn" {
  value = aws_dynamodb_table.app_clients.arn
}

output "app_logs_name" {
  value = aws_dynamodb_table.app_logs.name
}

output "all_table_arns" {
  description = "Dùng để gán quyền IAM cho Lambda"
  value = [
    aws_dynamodb_table.app_clients.arn,
    aws_dynamodb_table.app_logs.arn,
    aws_dynamodb_table.noti_ttl.arn
  ]
}