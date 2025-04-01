terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get existing VPC
data "aws_vpc" "vpc1" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Get existing private subnets
data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${var.private_subnet_name_prefix}*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc1.id]
  }
}

# Get existing public subnets
data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["${var.public_subnet_name_prefix}*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc1.id]
  }
}

# Get existing hosted zone
data "aws_route53_zone" "devlake" {
  name = var.hosted_zone_name
}

# Get secret for database credentials
data "aws_secretsmanager_secret" "devlake" {
  name = var.secret_name
}

data "aws_secretsmanager_secret_version" "devlake" {
  secret_id = data.aws_secretsmanager_secret.devlake.id
}

data "aws_caller_identity" "current" {}

# ECR Repository
resource "aws_ecr_repository" "devlake" {
  name = "devlake"
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "devlake-alb-sg"
  description = "Security group for DevLake ALB"
  vpc_id      = data.aws_vpc.vpc1.id

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
}

resource "aws_security_group" "ecs_tasks" {
  name        = "devlake-ecs-tasks-sg"
  description = "Security group for DevLake ECS tasks"
  vpc_id      = data.aws_vpc.vpc1.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "devlake" {
  name               = "devlake-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = data.aws_subnets.public.ids

  tags = {
    Name = "devlake-alb"
  }
}

# ALB Target Groups
resource "aws_lb_target_group" "devlake" {
  name        = "devlake-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc1.id
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
}

resource "aws_lb_target_group" "grafana" {
  name        = "grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc1.id
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
}

resource "aws_lb_target_group" "config_ui" {
  name        = "config-ui-tg"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc1.id
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
}

# DNS Records
resource "aws_route53_record" "devlake" {
  zone_id = data.aws_route53_zone.devlake.zone_id
  name    = "devlake.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.devlake.dns_name
    zone_id               = aws_lb.devlake.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = data.aws_route53_zone.devlake.zone_id
  name    = "grafana.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.devlake.dns_name
    zone_id               = aws_lb.devlake.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "config_ui" {
  zone_id = data.aws_route53_zone.devlake.zone_id
  name    = "config.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.devlake.dns_name
    zone_id               = aws_lb.devlake.zone_id
    evaluate_target_health = true
  }
} 