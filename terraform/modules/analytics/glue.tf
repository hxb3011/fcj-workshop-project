resource "aws_glue_catalog_database" "log_db" {
  name = "${var.project_name}_db"
}
resource "aws_iam_role" "glue_crawler_role" {
  name = "${var.project_name}-glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
resource "aws_iam_policy" "glue_s3_access" {
  name = "${var.project_name}-glue-s3-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        var.log_archive_bucket_arn,
        "${var.log_archive_bucket_arn}/*"
      ]
    }]
  })
}
resource "aws_iam_role_policy_attachment" "glue_s3_attach" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}
resource "aws_glue_crawler" "log_crawler" {
  database_name = aws_glue_catalog_database.log_db.name
  name          = "${var.project_name}-log-crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    path = "s3://${var.log_archive_bucket_name}/"
  }

  # Cấu hình để nhận diện đúng phân vùng Hive
  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  # Chạy hàng giờ để cập nhật dữ liệu mới
  schedule = "cron(0 * * * ? *)" 
}


