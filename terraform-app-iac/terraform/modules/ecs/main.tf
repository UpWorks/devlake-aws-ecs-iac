resource "aws_ecs_cluster" "devlake" {
  name = "${var.environment}-devlake-cluster"

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

resource "aws_ecs_service" "devlake" {
  name            = "${var.environment}-devlake"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = var.devlake_task_definition_arn
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

  depends_on = [aws_ecs_cluster.devlake]

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "grafana" {
  name            = "${var.environment}-grafana"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = var.grafana_task_definition_arn
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

  depends_on = [aws_ecs_cluster.devlake]

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "config_ui" {
  name            = "${var.environment}-config-ui"
  cluster         = aws_ecs_cluster.devlake.id
  task_definition = var.config_ui_task_definition_arn
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

  depends_on = [aws_ecs_cluster.devlake]

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "devlake" {
  name              = "/ecs/${var.environment}-devlake"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${var.environment}-grafana"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "config_ui" {
  name              = "/ecs/${var.environment}-config-ui"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
  }
} 