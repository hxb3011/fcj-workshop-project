variable "project_name" {
  type        = string
  description = "Tên dự án, dùng để prefix cho các tài nguyên"
  default     = ""
}

# --- S3 Log Archive (Nguồn dữ liệu) ---
variable "log_archive_bucket_name" {
  type        = string
  description = "Tên bucket chứa logs JSON (ví dụ: fcaj-log-archive)"
}

variable "log_archive_bucket_arn" {
  type        = string
  description = "ARN của bucket chứa logs để phân quyền cho Glue Crawler"
}

# --- S3 Athena Results (Nơi lưu kết quả truy vấn) ---
variable "athena_results_bucket_name" {
  type        = string
  description = "Tên bucket để Athena ghi kết quả truy vấn"
}

variable "athena_results_bucket_arn" {
  type        = string
  description = "ARN của bucket Athena kết quả để phân quyền cho Athena Workgroup"
}