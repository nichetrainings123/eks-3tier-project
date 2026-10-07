resource "aws_security_group" "this" {
  name        = "${var.name}-login-nlb"
  description = "Allow private VPC traffic to the login Network Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from within the VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Login NodePort to EKS nodes"
    from_port   = var.node_port
    to_port     = var.node_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-login-nlb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_nlb" {
  security_group_id            = var.node_security_group_id
  referenced_security_group_id = aws_security_group.this.id
  description                  = "Allow login NLB traffic to the Kubernetes NodePort"
  from_port                    = var.node_port
  to_port                      = var.node_port
  ip_protocol                  = "tcp"

  tags = var.tags
}

resource "aws_lb" "this" {
  name               = "${var.name}-login-nlb"
  internal           = true
  load_balancer_type = "network"
  ip_address_type    = "ipv4"
  subnets            = var.private_subnet_ids
  security_groups    = [aws_security_group.this.id]

  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, {
    Name = "${var.name}-login-nlb"
  })
}

resource "aws_lb_target_group" "login" {
  name        = "${var.name}-login-tg"
  port        = var.node_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = merge(var.tags, {
    Name = "${var.name}-login-tg"
  })
}

resource "aws_lb_listener" "login" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.login.arn
  }
}

resource "aws_autoscaling_attachment" "workers" {
  autoscaling_group_name = var.node_group_asg_name
  lb_target_group_arn    = aws_lb_target_group.login.arn
}
