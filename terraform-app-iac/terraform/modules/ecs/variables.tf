variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
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

variable "container_ports" {
  description = "Map of container ports for each service"
  type = map(object({
    container_port = number
    host_port     = number
    protocol      = string
  }))
}

variable "container_resources" {
  description = "Resource configurations for containers"
  type = map(object({
    cpu    = number
    memory = number
  }))
}

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "hosted_zone_name" {
  description = "Name of the Route53 hosted zone"
  type        = string
}

variable "devlake_image" {
  description = "Docker image for DevLake service"
  type        = string
}

variable "grafana_image" {
  description = "Docker image for Grafana service"
  type        = string
}

variable "config_ui_image" {
  description = "Docker image for Config UI service"
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