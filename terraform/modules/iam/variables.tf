variable "project_name" {
  type = string
}

variable "user_pool_arn" {
  type        = string
  description = "ARN của Cognito User Pool"
}

variable "app_clients_table_arn" {
  type        = string
  description = "ARN của bảng DynamoDB AppClients"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN của SNS Topic để subscribe"
}

#===============================================
variable "dynamodb_app_logs_arn" { type = string }
variable "log_archive_bucket_arn" { type = string }
variable "athena_results_bucket_arn" { type = string }
