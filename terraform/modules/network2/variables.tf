variable "project_name" {
  type        = string
  description = "Tên dự án để đặt prefix cho tài nguyên"
}

variable "vpc2_cidr" {
  type        = string
  default     = "10.1.0.0/16"
  description = "Dải IP của VPC 2 (Phải khác dải 10.0.0.0/16 của VPC cũ)"
}

variable "backend_port" {
  type        = number
  default     = 9000
  description = "Cổng mà ứng dụng Python Docker lắng nghe"
}

variable "enable_public_ip" {
  type        = bool
  default     = true
  description = "Tự động gán IP Public cho các resource trong Subnet này"
}