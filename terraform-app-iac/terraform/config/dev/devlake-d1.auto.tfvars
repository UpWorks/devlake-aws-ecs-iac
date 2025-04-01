aws_region = "us-west-2"
environment = "dev"

# VPC Configuration
vpc_name = "vpc1"
private_subnet_name_prefix = "private"
public_subnet_name_prefix = "public"

# DNS Configuration
hosted_zone_name = "devlake.aws-dev.replace-me.com"

# AWS Secrets Manager
secret_name = "devlaked1"

# ACM Certificate
acm_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/abcdef-1234-5678-90ab-cdef12345678"

# ECS Roles
ecs_execution_role_arn = "arn:aws:iam::123456789012:role/ecs-execution-role"
ecs_task_role_arn = "arn:aws:iam::123456789012:role/ecs-task-role"
ecs_tasks_security_group_id = "sg-1234567890abcdef0"

# Container Resource Configuration
container_resources = {
  devlake = {
    cpu    = 256
    memory = 512
  }
  grafana = {
    cpu    = 256
    memory = 512
  }
  config_ui = {
    cpu    = 256
    memory = 512
  }
}

# Container Port Configuration
container_ports = {
  devlake = {
    container_port = 8080
    host_port     = 8080
    protocol      = "tcp"
  }
  grafana = {
    container_port = 3000
    host_port     = 3000
    protocol      = "tcp"
  }
  config_ui = {
    container_port = 4000
    host_port     = 4000
    protocol      = "tcp"
  }
}

# Service Configuration
desired_count = 1

# Logging Configuration
log_retention_days = 30 