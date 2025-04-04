# ECR Repository Configuration
resource "aws_ecr_repository" "devlake" {
  name                 = "devlake/devlake"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.ecr_kms_key_id
  }
}

resource "aws_ecr_repository" "grafana" {
  name                 = "devlake-devlake-dashboard"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.ecr_kms_key_id
  }
}

resource "aws_ecr_repository" "config_ui" {
  name                 = "devlake/config-ui"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.ecr_kms_key_id
  }
}

# Get ACM certificate for the domain
data "aws_acm_certificate" "devlake" {
  domain      = "*.${data.aws_route53_zone.devlake.name}"
  statuses    = ["ISSUED"]
  most_recent = true
}

# HTTP to HTTPS redirect
resource "aws_lb_listener" "http" {
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

# HTTPS listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.devlake.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.config_ui.arn
  }
}

# HTTPS listener rules
resource "aws_lb_listener_rule" "devlake_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devlake.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "grafana_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana/*"]
    }
  }
}

# ALB Security Group
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