## API Gateway HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.prefix}-api"
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "gateway" {
  name = "/aws/lambda/${var.prefix}-lambda"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.main.id
  # stageが必要ならちゃんと設定しよう
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.gateway.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

# API Gateway を VPC Link で ALB に接続する
# JWT認証が通ったリクエストをALBに転送する

resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.prefix}-vpc-link"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = [aws_subnet.example1.id, aws_subnet.example2.id]
}

# ALB にアクセスできる Security Group を作成
resource "aws_security_group" "vpc_link" {
  name   = "${var.prefix}-vpc-link-sg"
  vpc_id = aws_vpc.example.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id = aws_apigatewayv2_api.main.id

  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.internal.arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.main.id
}

### JWT Authorizer
resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.main.id
  name             = "jwt-authorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.PreAuthorization"]
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.user_pool_client.id]
    issuer   = "https://${aws_cognito_user_pool.user_pool.endpoint}"
  }
}

# API Gateway → VPC Link → Internal NLB → External ALB へのルーティング
resource "aws_apigatewayv2_route" "api_sample" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  # jwt authorizerを設定
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
  # Cognitoでスコープを設定する場合はここで設定
  authorization_scopes = ["http://localhost:3000/basic"]
  target               = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

## Internal NLB
resource "aws_lb" "internal" {
  name               = "${var.prefix}-internal-nlb"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb-internal.id]
  subnets = [
    aws_subnet.example1.id,
    aws_subnet.example2.id
  ]

  enable_deletion_protection = false
}

# Internal NLBから External ALB に通信をフォワードするListener
resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.internal_tg.arn
  }
}

resource "aws_alb_target_group" "internal_tg" {
  name        = "${var.prefix}-internal-alb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.example.id
}

resource "aws_lb_target_group_attachment" "internal_to_external" {
  target_group_arn = aws_alb_target_group.internal_tg.arn
  target_id        = aws_lb.external.arn
  port             = 80
}

resource "aws_security_group" "nlb-internal" {
  name   = "${var.prefix}-nlb-internal-sg"
  vpc_id = aws_vpc.example.id

  # 特定のIP アドレスからのアクセスのみを許可
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    # API GW が紐づく VPC Link からのアクセスのみを許可
    security_groups = [
      aws_security_group.vpc_link.id
    ]
  }

  egress {
    from_port = 0
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      aws_vpc.example.cidr_block
    ]
  }
}
