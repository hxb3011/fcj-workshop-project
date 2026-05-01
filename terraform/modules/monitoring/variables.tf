variable "project_name" { type = string }
variable "log_group_name" { 
  type    = string
  default = "/app/log-project"
}
variable "retention_days" {
  type    = number
  default = 7
}
variable "filter_pattern" {
  type    = string
  default = ""
}
variable "shipper_lambda_arn" { type = string }
variable "shipper_lambda_name" { type = string }