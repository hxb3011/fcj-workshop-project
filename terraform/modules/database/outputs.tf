output "dynamodb_app_clients_name" {
  description = "Tên bảng lưu trữ thông tin đăng ký ứng dụng"
  value       = aws_dynamodb_table.app_clients.name
}

output "dynamodb_app_logs_name" {
  description = "Tên bảng lưu trữ log (Hot Storage)"
  value       = aws_dynamodb_table.app_logs.name
}
output "dynamodb_app_logs_arn" {
  description = "ARN của bảng AppLogs để module Analytics gán quyền"
  value       = aws_dynamodb_table.app_logs.arn
}
output "dynamodb_noti_ttl_name" {
  description = "Tên bảng kiểm soát tần suất gửi thông báo"
  value       = aws_dynamodb_table.noti_ttl.name
}
output "dynamodb_app_clients_arn" {
  description = "ARN của bảng đăng ký ứng dụng"
  value       = aws_dynamodb_table.app_clients.arn
}
output "dynamodb_all_table_arns" {
  description = "Danh sách ARN của tất cả các bảng để gán quyền IAM"
  value = [
    aws_dynamodb_table.app_clients.arn,
    aws_dynamodb_table.app_logs.arn,
    aws_dynamodb_table.noti_ttl.arn
  ]
}