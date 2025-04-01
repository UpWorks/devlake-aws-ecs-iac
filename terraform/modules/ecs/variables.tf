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

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "devlake_target_group_arn" {
  description = "ARN of the DevLake target group"
  type        = string
}

variable "grafana_target_group_arn" {
  description = "ARN of the Grafana target group"
  type        = string
}

variable "config_ui_target_group_arn" {
  description = "ARN of the Config UI target group"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
}

variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "devlake_image" {
  description = "DevLake container image"
  type        = string
}

variable "grafana_image" {
  description = "Grafana container image"
  type        = string
}

variable "config_ui_image" {
  description = "Config UI container image"
  type        = string
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