terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"  # Replace with your desired region
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

# ECS Cluster
resource "aws_ecs_cluster" "devlake" {
  name = "devlake-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
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

# ECS Tasks Security Group
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
  subnets           = data.aws_subnets.private.ids

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

resource "aws_lb_listener" "grafana_http" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

resource "aws_lb_listener" "config_ui_http" {
  load_balancer_arn = aws_lb.devlake.arn
  port              = 4000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.config_ui.arn
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "devlake" {
  family                   = "devlake"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "devlake"
      image = "${aws_ecr_repository.devlake.repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_URL"
          value = "mysql://${jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["username"]}:${jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["password"]}@${jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["host"]}:${jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["port"]}/${jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["database"]}?charset=utf8mb4&parseTime=True&loc=UTC"
        },
        {
          name  = "PORT"
          value = "8080"
        },
        {
          name  = "MODE"
          value = "release"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/devlake"
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = "devlake.docker.scarf.sh/apache/devlake-dashboard:v1.0.2-beta7"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "MYSQL_URL"
          value = "${jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["host"]}:${jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["port"]}"
        },
        {
          name  = "MYSQL_DATABASE"
          value = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["database"]
        },
        {
          name  = "MYSQL_USER"
          value = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["username"]
        },
        {
          name  = "MYSQL_PASSWORD"
          value = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["password"]
        },
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "https://${aws_lb.devlake.dns_name}:3000"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/grafana"
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "config_ui" {
  family                   = "config-ui"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "config-ui"
      image = "devlake.docker.scarf.sh/apache/devlake-config-ui:v1.0.2-beta7"
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DEVLAKE_ENDPOINT"
          value = "https://${aws_lb.devlake.dns_name}:8080"
        },
        {
          name  = "GRAFANA_ENDPOINT"
          value = "https://${aws_lb.devlake.dns_name}:3000"
        },
        {
          name  = "TZ"
          value = "UTC"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/config-ui"
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Services
resource "aws_ecs_service" "devlake" {
  name            = "devlake"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.devlake.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.private.ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.devlake.arn
    container_name   = "devlake"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.devlake_https]
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.private.ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.grafana_http]
}

resource "aws_ecs_service" "config_ui" {
  name            = "config-ui"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.config_ui.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.private.ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.config_ui.arn
    container_name   = "config-ui"
    container_port   = 4000
  }

  depends_on = [aws_lb_listener.config_ui_http]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "devlake" {
  name              = "/ecs/devlake"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/grafana"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "config_ui" {
  name              = "/ecs/config-ui"
  retention_in_days = 30
}

# Route53 Records
resource "aws_route53_record" "devlake" {
  zone_id = data.aws_route53_zone.devlake.zone_id
  name    = "devlake.${data.aws_route53_zone.devlake.name}"
  type    = "A"

  alias {
    name                   = aws_lb.devlake.dns_name
    zone_id               = aws_lb.devlake.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = data.aws_route53_zone.devlake.zone_id
  name    = "grafana.${data.aws_route53_zone.devlake.name}"
  type    = "A"

  alias {
    name                   = aws_lb.devlake.dns_name
    zone_id               = aws_lb.devlake.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "config_ui" {
  zone_id = data.aws_route53_zone.devlake.zone_id
  name    = "config.${data.aws_route53_zone.devlake.name}"
  type    = "A"

  alias {
    name                   = aws_lb.devlake.dns_name
    zone_id               = aws_lb.devlake.zone_id
    evaluate_target_health = true
  }
}

module "security" {
  source = "./modules/security"

  environment           = var.environment
  vpc_id               = data.aws_vpc.vpc1.id
  alb_security_group_id = module.alb.alb_security_group_id
  container_ports       = var.container_ports
  secrets_manager_arn   = data.aws_secretsmanager_secret.devlake.arn
  aws_region           = var.aws_region
  aws_account_id       = data.aws_caller_identity.current.account_id
}

module "alb" {
  source = "./modules/alb"

  environment         = var.environment
  vpc_id             = data.aws_vpc.vpc1.id
  private_subnet_ids = data.aws_subnets.private.ids
  acm_certificate_arn = var.acm_certificate_arn
  container_ports     = var.container_ports
}

module "ecs" {
  source = "./modules/ecs"

  environment                = var.environment
  aws_region                = var.aws_region
  container_ports           = var.container_ports
  container_resources       = var.container_resources
  ecs_execution_role_arn    = module.security.ecs_execution_role_arn
  ecs_task_role_arn         = module.security.ecs_task_role_arn
  private_subnet_ids        = data.aws_subnets.private.ids
  ecs_tasks_security_group_id = module.security.ecs_tasks_security_group_id
  devlake_target_group_arn  = module.alb.devlake_target_group_arn
  grafana_target_group_arn  = module.alb.grafana_target_group_arn
  config_ui_target_group_arn = module.alb.config_ui_target_group_arn
  alb_dns_name             = module.alb.alb_dns_name
  db_username              = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["username"]
  db_password              = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["password"]
  db_host                  = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["host"]
  db_port                  = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["port"]
  db_name                  = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["database"]
  devlake_image           = "devlake.docker.scarf.sh/apache/devlake:v1.0.2-beta7"
  grafana_image           = "devlake.docker.scarf.sh/apache/devlake-dashboard:v1.0.2-beta7"
  config_ui_image         = "devlake.docker.scarf.sh/apache/devlake-config-ui:v1.0.2-beta7"
  desired_count           = var.desired_count
  log_retention_days      = var.log_retention_days
}

module "dns" {
  source = "./modules/dns"

  environment      = var.environment
  hosted_zone_id  = data.aws_route53_zone.devlake.zone_id
  hosted_zone_name = var.hosted_zone_name
  alb_dns_name    = module.alb.alb_dns_name
  alb_zone_id     = module.alb.alb_zone_id
} 