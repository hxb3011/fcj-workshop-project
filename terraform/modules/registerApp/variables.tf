variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "container_image" {
  type        = string
  description = "Link image từ Docker Hub"
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "cpu" {
  type    = string
  default = "256"
}

variable "memory" {
  type    = string
  default = "512"
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "user_pool_id" {
  type = string
}

variable "table_name" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "log_policy_arn" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}