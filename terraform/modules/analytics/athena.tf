# Athena Workgroup
resource "aws_athena_workgroup" "log_workgroup" {
  name          = "${var.project_name}-workgroup"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_results_bucket_name}/results/"
    }
  }
}