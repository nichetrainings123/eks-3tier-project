resource "aws_security_group" "vpc_link" {
  name        = "${var.name}-api-vpc-link-${var.random_suffix}"
  description = "Allow API Gateway VPC Link egress to the private login NLB"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-api-vpc-link"
  })
}

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${var.name}-login"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-login-vpc-link"
  })
}

resource "aws_apigatewayv2_api" "this" {
  name          = "${var.name}-login"
  protocol_type = "HTTP"

  tags = merge(var.tags, {
    Name = "${var.name}-login-api"
  })
}

resource "aws_apigatewayv2_integration" "this" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = var.nlb_listener_arn
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.this.id
}

resource "aws_apigatewayv2_route" "this" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}
