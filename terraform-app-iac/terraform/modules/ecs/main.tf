resource "aws_ecs_cluster" "devlake" {
  name = "devlake-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_task_definition" "devlake" {
  family                   = "devlake-${var.environment}"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.container_resources.devlake.cpu
  memory                  = var.container_resources.devlake.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn          = var.ecs_task_role_arn

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
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.devlake.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana-${var.environment}"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.container_resources.grafana.cpu
  memory                  = var.container_resources.grafana.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn          = var.ecs_task_role_arn

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
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_task_definition" "config_ui" {
  family                   = "config-ui-${var.environment}"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.container_resources.config_ui.cpu
  memory                  = var.container_resources.config_ui.memory
  execution_role_arn      = var.ecs_execution_role_arn
  task_role_arn          = var.ecs_task_role_arn

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
          value = "devlake:8080"
        },
        {
          name  = "GRAFANA_ENDPOINT"
          value = "grafana:3000"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.config_ui.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "devlake" {
  name            = "devlake-${var.environment}"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.devlake.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.devlake_target_group_arn
    container_name   = "devlake"
    container_port   = var.container_ports.devlake.container_port
  }

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana-${var.environment}"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.grafana_target_group_arn
    container_name   = "grafana"
    container_port   = var.container_ports.grafana.container_port
  }

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "config_ui" {
  name            = "config-ui-${var.environment}"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = aws_ecs_task_definition.config_ui.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.config_ui_target_group_arn
    container_name   = "config-ui"
    container_port   = var.container_ports.config_ui.container_port
  }

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "devlake" {
  name              = "/ecs/devlake-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/grafana-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "config_ui" {
  name              = "/ecs/config-ui-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
} 