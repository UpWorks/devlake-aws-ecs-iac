# DevLake Task Definition
resource "aws_ecs_task_definition" "devlake" {
  family                   = "devlake"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 1024
  memory                  = 2048
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
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
          value = "mysql://${local.db_credentials.username}:${local.db_credentials.password}@${local.db_credentials.host}:${local.db_credentials.port}/${local.db_credentials.dbname}?charset=utf8mb4&parseTime=True&loc=UTC"
        },
        {
          name  = "MODE"
          value = "release"
        },
        {
          name  = "PORT"
          value = "8080"
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

# Grafana Task Definition
resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 512
  memory                  = 1024
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
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
          name  = "GF_SERVER_ROOT_URL"
          value = "http://localhost:4000/grafana"
        },
        {
          name  = "GF_USERS_DEFAULT_THEME"
          value = "light"
        },
        {
          name  = "MYSQL_URL"
          value = "${local.db_credentials.host}:${local.db_credentials.port}"
        },
        {
          name  = "MYSQL_DATABASE"
          value = local.db_credentials.dbname
        },
        {
          name  = "MYSQL_USER"
          value = local.db_credentials.username
        },
        {
          name  = "MYSQL_PASSWORD"
          value = local.db_credentials.password
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

# Config UI Task Definition
resource "aws_ecs_task_definition" "config_ui" {
  family                   = "config-ui"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
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

  depends_on = [aws_lb_listener.http]
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

  depends_on = [aws_lb_listener.http]
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

  depends_on = [aws_lb_listener.http]
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

  ingress {
    from_port       = 4000
    to_port         = 4000
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