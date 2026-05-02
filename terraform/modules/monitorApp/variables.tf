variable "project_name" {
  type        = string
  description = "Tên dự án để đặt tên cho EC2"
}

variable "subnet_id" {
  type        = string
  description = "ID của subnet trong network2 (VPC mới)"
}

variable "security_group_id" {
  type        = string
  description = "ID của security group mở cổng 9000 và 22"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}


variable "iam_instance_profile_name" {
  type        = string
  description = "Tên của IAM Instance Profile để gán quyền cho EC2"
}


variable "app_env_vars" {
  type        = map(string)
  default     = {}
  description = "Danh sách các biến môi trường truyền vào Docker container"
}