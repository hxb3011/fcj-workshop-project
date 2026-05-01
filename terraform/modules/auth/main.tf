resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-user-pool"

  admin_create_user_config {
    allow_admin_create_user_only = var.admin_create_user_only
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name = "${var.project_name}-client"

  user_pool_id    = aws_cognito_user_pool.this.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  id_token_validity      = 24
  access_token_validity  = 24
  refresh_token_validity = 30

  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${var.project_name}-auth-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.this.id
}