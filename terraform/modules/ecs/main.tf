locals {
  common_tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
    Owner       = "platform-team"
    CostCenter  = "platform"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "devlake" {
  name = "${var.environment}-devlake-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "devlake" {
  family                   = "devlake"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.container_resources.devlake.cpu
  memory                  = var.container_resources.devlake.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "devlake"
      image = var.devlake_image
      portMappings = [
        {
          containerPort = var.container_ports.devlake.container_port
          hostPort      = var.container_ports.devlake.host_port
          protocol      = var.container_ports.devlake.protocol
        }
      ]
      environment = [
        {
          name  = "DB_URL"
          value = "mysql://${var.db_username}:${var.db_password}@${var.db_host}:${var.db_port}/${var.db_name}?charset=utf8mb4&parseTime=True&loc=UTC"
        },
        {
          name  = "PORT"
          value = tostring(var.container_ports.devlake.container_port)
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
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.container_resources.grafana.cpu
  memory                  = var.container_resources.grafana.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = var.grafana_image
      portMappings = [
        {
          containerPort = var.container_ports.grafana.container_port
          hostPort      = var.container_ports.grafana.host_port
          protocol      = var.container_ports.grafana.protocol
        }
      ]
      environment = [
        {
          name  = "MYSQL_URL"
          value = "${var.db_host}:${var.db_port}"
        },
        {
          name  = "MYSQL_DATABASE"
          value = var.db_name
        },
        {
          name  = "MYSQL_USER"
          value = var.db_username
        },
        {
          name  = "MYSQL_PASSWORD"
          value = var.db_password
        },
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "https://${var.alb_dns_name}:${var.container_ports.grafana.container_port}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/grafana"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "config_ui" {
  family                   = "config-ui"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.container_resources.config_ui.cpu
  memory                  = var.container_resources.config_ui.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "config-ui"
      image = var.config_ui_image
      portMappings = [
        {
          containerPort = var.container_ports.config_ui.container_port
          hostPort      = var.container_ports.config_ui.host_port
          protocol      = var.container_ports.config_ui.protocol
        }
      ]
      environment = [
        {
          name  = "DEVLAKE_ENDPOINT"
          value = "https://${var.alb_dns_name}:${var.container_ports.devlake.container_port}"
        },
        {
          name  = "GRAFANA_ENDPOINT"
          value = "https://${var.alb_dns_name}:${var.container_ports.grafana.container_port}"
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
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}

# ECS Services
resource "aws_ecs_service" "devlake" {
  name            = "devlake"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.devlake.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_tasks_security_group_id]
  }

  load_balancer {
    target_group_arn = var.devlake_target_group_arn
    container_name   = "devlake"
    container_port   = var.container_ports.devlake.container_port
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_tasks_security_group_id]
  }

  load_balancer {
    target_group_arn = var.grafana_target_group_arn
    container_name   = "grafana"
    container_port   = var.container_ports.grafana.container_port
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "config_ui" {
  name            = "config-ui"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.config_ui.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_tasks_security_group_id]
  }

  load_balancer {
    target_group_arn = var.config_ui_target_group_arn
    container_name   = "config-ui"
    container_port   = var.container_ports.config_ui.container_port
  }

  tags = local.common_tags
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "devlake" {
  name              = "/ecs/devlake"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/grafana"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "config_ui" {
  name              = "/ecs/config-ui"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
} 