variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
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