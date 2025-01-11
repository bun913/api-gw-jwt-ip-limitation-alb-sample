output "base_url" {
  description = "The base URL of the API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

// https://sample-jwt-auth-user-pool.auth.ap-northeast-1.amazoncognito.com/oauth2/token
output "oauth_url" {
  value       = "https://${aws_cognito_user_pool.user_pool.domain}.auth.${var.region}.amazoncognito.com/oauth2/token"
  description = "The OAuth URL of the Cognito User Pool"
}

output "external_ip_limited_endpoint" {
  value       = aws_lb.external.dns_name
  description = "The DNS name of the ALB"
}

output "client_id" {
  value       = aws_cognito_user_pool_client.user_pool_client.id
  description = "The client ID of the Cognito User Pool"
}
