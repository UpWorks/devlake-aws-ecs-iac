locals {
  common_tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
    Owner       = "platform-team"
    CostCenter  = "platform"
  }
}

# ECS Tasks Security Group
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-devlake-ecs-tasks-sg"
  description = "Security group for DevLake ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_ports.devlake.container_port
    to_port         = var.container_ports.devlake.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    from_port       = var.container_ports.grafana.container_port
    to_port         = var.container_ports.grafana.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    from_port       = var.container_ports.config_ui.container_port
    to_port         = var.container_ports.config_ui.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-devlake-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-devlake-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Allow ECS tasks to access Secrets Manager
resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.environment}-devlake-secrets-access"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.secrets_manager_arn
        ]
      }
    ]
  })
}

# Allow ECS tasks to write CloudWatch logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.environment}-devlake-cloudwatch-logs"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/ecs/*:*"
        ]
      }
    ]
  })
} 