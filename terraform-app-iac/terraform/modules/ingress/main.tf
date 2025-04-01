resource "aws_lb" "devlake" {
  name               = "${var.environment}-devlake-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = var.public_subnet_ids

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

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

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

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

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No route matched"
      status_code  = "404"
    }
  }

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

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
    matcher            = "200"
    path               = "/ping"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 3
  }

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
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
    matcher            = "200"
    path               = "/api/health"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 3
  }

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
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
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 3
  }

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_listener_rule" "devlake" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devlake.arn
  }

  condition {
    host_header {
      values = ["devlake.${var.hosted_zone_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    host_header {
      values = ["grafana.${var.hosted_zone_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "config_ui" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.config_ui.arn
  }

  condition {
    host_header {
      values = ["config.${var.hosted_zone_name}"]
    }
  }
} 