output "base_url" {
  description = "The base URL of the API Gateway"
  value       = aws_apigatewayv2_api.lambda.api_endpoint
}
