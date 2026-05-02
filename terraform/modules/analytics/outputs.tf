# --- Glue Outputs ---

output "glue_database_name" {
  description = "Tên của Glue Catalog Database"
  value       = aws_glue_catalog_database.log_db.name
}

output "glue_crawler_name" {
  description = "Tên của Glue Crawler để có thể trigger bằng SDK nếu cần"
  value       = aws_glue_crawler.log_crawler.name
}

output "glue_crawler_arn" {
  description = "ARN của Glue Crawler"
  value       = aws_glue_crawler.log_crawler.arn
}

# --- Athena Outputs ---

output "athena_workgroup_name" {
  description = "Tên của Athena Workgroup"
  value       = aws_athena_workgroup.log_workgroup.name
}

output "athena_workgroup_arn" {
  description = "ARN của Athena Workgroup"
  value       = aws_athena_workgroup.log_workgroup.arn
}

# --- IAM Outputs (Cho Lambda Getter sử dụng) ---

output "glue_crawler_role_arn" {
  description = "IAM Role ARN mà Crawler đang sử dụng"
  value       = aws_iam_role.glue_crawler_role.arn
}