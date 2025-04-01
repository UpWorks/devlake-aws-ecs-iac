# AWS Region
aws_region = "us-west-2"

# Environment
environment = "dev"

# VPC Configuration
vpc_name = "vpc1"
private_subnet_name_prefix = "private"

# DNS Configuration
hosted_zone_name = "devlake.aws-dev.replace-me.com"

# AWS Secrets Manager
secret_name = "devlaked1"

# ACM Certificate
acm_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/your-certificate-id"

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