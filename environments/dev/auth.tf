resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.prefix}-user-pool"

  username_attributes = [] #識別子にメールは使わない
  mfa_configuration   = "OFF"
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "${var.prefix}-user-pool"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_resource_server" "main" {
  identifier = "http://localhost:3000"
  scope {
    # スコープ名はAPI Gatewayのスコープ名と一致させる
    scope_name        = "basic"
    scope_description = "Allow Access to the API"
  }
  name         = "example-api"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                                 = "${var.prefix}-client-staging"
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes                 = ["http://localhost:3000/basic"]
  access_token_validity                = 24 # hours
  enable_token_revocation              = true

  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH"]
}
