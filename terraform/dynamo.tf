resource "aws_dynamodb_table" "app_clients" {
  name           = "AppClients"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "appId"

  attribute {
    name = "appId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "app_logs" {
  name           = "AppLogs"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "appId"
  range_key      = "timestamp"

  attribute {
    name = "appId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }
}

resource "aws_dynamodb_table" "noti_ttl" {
  name           = "NotiTTL"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "appId"

  attribute {
    name = "appId"
    type = "S"
  }

  ttl {
    attribute_name = "expireAt"
    enabled        = true
  }
}