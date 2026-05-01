# Bucket lưu trữ Log lâu dài
resource "aws_s3_bucket" "log_archive" {
  bucket = "${var.project_name}-log-archive"
}

resource "aws_s3_bucket_lifecycle_configuration" "log_archive_lifecycle" {
  bucket = aws_s3_bucket.log_archive.id

  rule {
    id     = "archive_old_logs"
    status = "Enabled"
    filter {} 

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = 365
    }
  }
}

# Bucket lưu trữ kết quả truy vấn Athena
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-athena-queries-output"
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results_lifecycle" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "cleanup_old_results"
    status = "Enabled"
    filter {} 

    expiration {
      days = 7
    }
  }
}