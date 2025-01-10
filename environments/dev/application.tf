# ここには本来 ALB + EC2（ECS）などのリソースが定義されているとします
# そしてALBには本来特定のIPアドレスからのアクセスのみを許可していました
# それに加えて、今回はAPI GatewayのJWT認証をくぐり抜けたリクエストを許可するようにします
# 今回はALBのターゲットはLambdaにしています

## Lambda ( Web Application を再現)
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "lambda_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "archive_file" "lambda_zip" {
  type = "zip"

  source_dir  = "${path.cwd}/functions/"
  output_path = "${path.cwd}/archives/lambda.zip"
}

resource "aws_lambda_function" "hello_world" {
  function_name = "${var.prefix}-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "sample.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.lambda_zip.output_path
}

## Extenal ALB

resource "aws_lb" "external" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.example1.id,
    aws_subnet.example2.id
  ]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "external" {
  load_balancer_arn = aws_lb.external.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tg.arn
  }
}

resource "aws_alb_target_group" "tg" {
  name        = "${var.prefix}-alb-tg"
  target_type = "lambda"
}

resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = aws_vpc.example.id

  # 特定のIP アドレスからのアクセスのみを許可
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ip] # 特定のIPアドレスを許可されている状態
    # ここは Internal NLBを追加後に追記する部分
    security_groups = [
      aws_security_group.nlb-internal.id
    ]
  }

  # 任意の送信を許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_alb_target_group.tg.arn
  target_id        = aws_lambda_function.hello_world.arn
}

# aws_lambda_permission
resource "aws_lambda_permission" "alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_alb_target_group.tg.arn
}
