module "iam" {
  source                = "./modules/iam"
  project_name          = "fcaj-v2"
  user_pool_arn         = module.auth.user_pool_arn
  app_clients_table_arn = module.database.dynamodb_app_clients_name.arn
  sns_topic_arn         = module.messaging.sns_topic_arn
}

module "network" {
  source       = "./modules/network"
  project_name = "fcaj-v2"
}
module "database" {
  source       = "./modules/database"
  project_name = "fcaj-v2" 
}
module "storage" {
  source       = "./modules/storage"
  project_name = "fcaj-v2"
}
module "messaging" {
  source       = "./modules/messaging"
  project_name = "fcaj-v2"
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
  filename      = "processor" 
  timeout       = 60       
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
      Resource = tolist(module.database.dynamodb_all_table_arns)
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
module "auth" {
  source       = "./modules/auth"
  project_name = "log-system" 
}

module "monitoring" {
  source              = "./modules/monitoring"
  project_name        = "log_system"
  log_group_name      = "/app/log-project"
  
  shipper_lambda_arn  = module.shipper_lambda.lambda_function_arn
  shipper_lambda_name = module.shipper_lambda.lambda_function_name
}
resource "aws_lambda_event_source_mapping" "sqs_to_processor" {
  event_source_arn = module.messaging.sqs_queue_arn
  function_name    = module.processor_lambda.lambda_function_arn
  batch_size       = 10 
}
# module "register_app" {
#   source          = "./modules/registerApp"
#   project_name    = "fcaj-v2-api"
#   aws_region      = "ap-southeast-1"
  

#   app_port        = 8000 
#   container_image = "docker.io/your_docker_username/register-app:latest"


#   subnets         = module.network.public_subnets
#   security_groups = [module.network.ecs_sg_id]


#   user_pool_id   = module.auth.user_pool_id
#   table_name     = module.database.dynamodb_app_clients_name
#   sns_topic_arn  = module.messaging.sns_topic_arn
#   log_policy_arn = module.monitoring.log_pusher_policy_arn

 
#   execution_role_arn = module.iam.execution_role_arn
#   task_role_arn      = module.iam.task_role_arn
# }