# # Định nghĩa hàm Lambda Getter
# resource "aws_lambda_function" "log_getter" {
#   filename      = "getter.zip"
#   function_name = "Log_Getter_App"
  
#   # Tham chiếu đến Role từ file athena.tf
#   role          = aws_iam_role.getter_role.arn 
  
#   handler       = "getter.lambda_handler"
#   runtime       = "python3.9"

#   environment {
#     variables = {
#       TABLE_LOGS       = "AppLogs"
#       GLUE_DATABASE    = aws_glue_catalog_database.log_db.name
#       ATHENA_WORKGROUP = aws_athena_workgroup.log_project_workgroup.name
#     }
#   }
# }