output "base_url" {
  description = "The base URL of the API Gateway"
  value       = aws_apigatewayv2_api.lambda.api_endpoint
}

output "oauth_url" {
  value       = "https://${aws_cognito_user_pool.user_pool.endpoint}/oauth2/token"
  description = "The OAuth URL of the Cognito User Pool"
}
