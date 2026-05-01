module "database" {
  source       = "./modules/database"
  project_name = "" 
}
module "storage" {
  source       = "./modules/storage"
  project_name = ""
}
module "messaging" {
  source       = "./modules/messaging"
  project_name = ""
}
module "shipper_lambda" {
  source        = "./modules/compute"
  function_name = "shipper"
  filename      = "shipper" 

  environment_variables = {
    SQS_URL = module.messaging.sqs_queue_url
  }
  additional_policies = [
    {
      Effect   = "Allow"
      Action   = ["sqs:SendMessage", "sqs:GetQueueAttributes"]
      Resource = [module.messaging.sqs_queue_arn]
    }
  ]
}

module "processor_lambda" {
  source        = "./modules/compute"
  function_name = "processor"
  filename      = "processor" # Tìm file processor.py ở gốc
  timeout       = 60           # Tăng timeout cho xử lý batch/parallel
  memory_size   = 256

  environment_variables = {
    TABLE_LOGS    = module.database.dynamodb_app_logs_name
    TABLE_NOTI    = module.database.dynamodb_noti_ttl_name
    BUCKET_NAME   = module.storage.log_archive_bucket_id
    SNS_TOPIC_ARN = module.messaging.sns_topic_arn
  }

  additional_policies = [
    {
      Effect   = "Allow"
      Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      Resource = [module.messaging.sqs_queue_arn]
    },
    {
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:BatchWriteItem"]
      Resource = module.database.dynamodb_all_table_arns
    },
    {
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = ["${module.storage.log_archive_bucket_arn}/*"]
    },
    {
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = [module.messaging.sns_topic_arn]
    }
  ]
}

resource "aws_lambda_event_source_mapping" "sqs_to_processor" {
  event_source_arn = module.messaging.sqs_queue_arn
  function_name    = module.processor_lambda.lambda_function_arn
  batch_size       = 10 
}
module "monitoring" {
  source              = "./modules/monitoring"
  project_name        = "log_system"
  log_group_name      = "/app/log-project"
  
  shipper_lambda_arn  = module.shipper_lambda.lambda_function_arn
  shipper_lambda_name = module.shipper_lambda.lambda_function_name
}