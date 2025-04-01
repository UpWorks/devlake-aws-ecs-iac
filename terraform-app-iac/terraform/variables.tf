variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "vpc_name" {
  description = "Name of the existing VPC"
  type        = string
}

variable "private_subnet_name_prefix" {
  description = "Prefix for private subnet names"
  type        = string
}

variable "public_subnet_name_prefix" {
  description = "Prefix for public subnet names"
  type        = string
}

variable "hosted_zone_name" {
  description = "Name of the Route53 hosted zone"
  type        = string
}

variable "secret_name" {
  description = "Name of the AWS Secrets Manager secret"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "ecs_tasks_security_group_id" {
  description = "ID of the security group for ECS tasks"
  type        = string
}

variable "container_ports" {
  description = "Map of container ports for each service"
  type = map(object({
    container_port = number
    host_port     = number
    protocol      = string
  }))
  default = {
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
}

variable "container_resources" {
  description = "Resource configurations for containers"
  type = map(object({
    cpu    = number
    memory = number
  }))
  default = {
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
}

variable "devlake_image" {
  description = "Docker image for DevLake service"
  type        = string
  default     = "devlake.docker.scarf.sh/apache/devlake:v1.0.2-beta7"
}

variable "grafana_image" {
  description = "Docker image for Grafana service"
  type        = string
  default     = "devlake.docker.scarf.sh/apache/devlake-dashboard:v1.0.2-beta7"
}

variable "config_ui_image" {
  description = "Docker image for Config UI service"
  type        = string
  default     = "devlake.docker.scarf.sh/apache/devlake-config-ui:v1.0.2-beta7"
}

variable "desired_count" {
  description = "Desired number of tasks to run"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
} 