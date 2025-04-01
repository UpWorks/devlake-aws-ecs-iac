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

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.config_ui.arn
  }
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "devlake" {
  listener_arn = aws_lb_listener.http.arn
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

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.http.arn
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