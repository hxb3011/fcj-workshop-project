output "log_archive_bucket_id" {
  value = aws_s3_bucket.log_archive.id
}

output "log_archive_bucket_arn" {
  value = aws_s3_bucket.log_archive.arn
}

output "athena_results_bucket_id" {
  value = aws_s3_bucket.athena_results.id
}
output "all_s3_arns" {
  description = "Dùng để gán quyền IAM cho Lambda"
  value = [
    aws_s3_bucket.log_archive.id,
    aws_s3_bucket.log_archive.arn,
    aws_s3_bucket.athena_results.id
  ]
}