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
    matcher            = "200"
    path               = "/ping"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 3
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
    matcher            = "200"
    path               = "/api/health"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 3
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
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 3
  }
}

# Application Load Balancer
resource "aws_lb" "devlake" {
  name               = "devlake-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = data.aws_subnets.private.ids

  tags = {
    Name = "devlake-alb"
  }
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

# ALB Target Group Attachments
resource "aws_lb_target_group_attachment" "devlake" {
  target_group_arn = aws_lb_target_group.devlake.arn
  target_id        = aws_ecs_service.devlake.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "grafana" {
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = aws_ecs_service.grafana.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "config_ui" {
  target_group_arn = aws_lb_target_group.config_ui.arn
  target_id        = aws_ecs_service.config_ui.id
  port             = 4000
}

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