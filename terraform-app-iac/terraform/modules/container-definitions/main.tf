locals {
  common_container_definition = {
    essential = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
}

resource "aws_ecs_task_definition" "devlake" {
  family                   = "${var.environment}-devlake"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.container_resources.devlake.cpu
  memory                  = var.container_resources.devlake.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    merge(local.common_container_definition, {
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
        },
        {
          name  = "LOGGING_LEVEL"
          value = "Info"
        },
        {
          name  = "ENABLE_STACKTRACE"
          value = "true"
        },
        {
          name  = "RESUME_PIPELINES"
          value = "true"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_ports.devlake.container_port}/ping || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    })
  ])
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.environment}-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.container_resources.grafana.cpu
  memory                  = var.container_resources.grafana.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    merge(local.common_container_definition, {
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
          name  = "GF_SERVER_ROOT_URL"
          value = "https://grafana.${var.hosted_zone_name}"
        },
        {
          name  = "GF_USERS_DEFAULT_THEME"
          value = "light"
        },
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
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_ports.grafana.container_port}/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    })
  ])
}

resource "aws_ecs_task_definition" "config_ui" {
  family                   = "${var.environment}-config-ui"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.container_resources.config_ui.cpu
  memory                  = var.container_resources.config_ui.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    merge(local.common_container_definition, {
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
          value = "https://devlake.${var.hosted_zone_name}"
        },
        {
          name  = "GRAFANA_ENDPOINT"
          value = "https://grafana.${var.hosted_zone_name}"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_ports.config_ui.container_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    })
  ])
} 