# resource "aws_glue_catalog_database" "log_db" {
#   name = "app_logs_database" 
# }
# resource "aws_glue_catalog_table" "app_logs_table" {
#   name          = "app_logs"
#   database_name = aws_glue_catalog_database.log_db.name
#   table_type    = "EXTERNAL_TABLE"

#   parameters = {
#     "classification"                    = "json"
#     "projection.enabled"                = "true"
    
#     # Cấu hình cho năm (year)
#     "projection.year.type"              = "integer"
#     "projection.year.range"             = "2024,2030"
#     "projection.year.digits"            = "4"
    
#     # Cấu hình cho tháng (month)
#     "projection.month.type"             = "integer"
#     "projection.month.range"            = "1,12"
#     "projection.month.digits"           = "2"
    
#     # Cấu hình cho ngày (day)
#     "projection.day.type"               = "integer"
#     "projection.day.range"              = "1,31"
#     "projection.day.digits"             = "2"
    
#     # Cấu hình cho appId (Vì appId là vô hạn/không cố định, ta dùng kiểu 'injected')
#     "projection.appid.type"             = "injected"

#     # Định nghĩa cấu trúc thư mục trên S3
#     "storage.location.template"         = "s3://fcaj-log-archive-project/year=$${year}/month=$${month}/day=$${day}/appId=$${appid}/"
#   }

#   storage_descriptor {
#     location      = "s3://fcaj-log-archive-project/"
#     input_format  = "org.apache.hadoop.mapred.TextInputFormat"
#     output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

#     ser_de_info {
#       name                  = "json-ser-de"
#       serialization_library = "org.openx.data.jsonserde.JsonSerDe"
#     }

#     columns {
#       name = "timestamp"
#       type = "bigint"
#     }
#     columns {
#       name = "level"
#       type = "string"
#     }
#     columns {
#       name = "message"
#       type = "string"
#     }
#   }

#   partition_keys {
#     name = "year"
#     type = "string"
#   }
#   partition_keys {
#     name = "month"
#     type = "string"
#   }
#   partition_keys {
#     name = "day"
#     type = "string"
#   }
#   partition_keys {
#     name = "appid"
#     type = "string"
#   }
# }