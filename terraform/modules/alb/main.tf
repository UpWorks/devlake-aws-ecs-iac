locals {
  common_tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
    Owner       = "platform-team"
    CostCenter  = "platform"
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-devlake-alb-sg"
  description = "Security group for DevLake ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# Application Load Balancer
resource "aws_lb" "devlake" {
  name               = "${var.environment}-devlake-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.private_subnet_ids

  tags = local.common_tags
}

# ALB Target Groups
resource "aws_lb_target_group" "devlake" {
  name        = "${var.environment}-devlake-tg"
  port        = var.container_ports.devlake.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    timeout             = 5
    path                = "/ping"
    port                = "traffic-port"
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "grafana" {
  name        = "${var.environment}-grafana-tg"
  port        = var.container_ports.grafana.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    timeout             = 5
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "config_ui" {
  name        = "${var.environment}-config-ui-tg"
  port        = var.container_ports.config_ui.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    timeout             = 5
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

# ALB Listeners
resource "aws_lb_listener" "devlake_http" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "devlake_https" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devlake.arn
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "grafana_http" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "config_ui_http" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 4000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.config_ui.arn
  }

  tags = local.common_tags
} 