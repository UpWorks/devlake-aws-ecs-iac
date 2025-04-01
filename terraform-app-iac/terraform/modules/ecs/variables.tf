variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
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
}

variable "devlake_task_definition_arn" {
  description = "ARN of the DevLake task definition"
  type        = string
}

variable "grafana_task_definition_arn" {
  description = "ARN of the Grafana task definition"
  type        = string
}

variable "config_ui_task_definition_arn" {
  description = "ARN of the Config UI task definition"
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