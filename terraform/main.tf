terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# AWS Account and Region Variables
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

# Variables for container images
variable "devlake_ecr_repo" {
  description = "ECR repository URL for DevLake container"
  type        = string
}

variable "grafana_ecr_repo" {
  description = "ECR repository URL for Grafana container"
  type        = string
}

variable "config_ui_ecr_repo" {
  description = "ECR repository URL for Config UI container"
  type        = string
}

# Get existing VPC
data "aws_vpc" "vpc1" {
  filter {
    name   = "tag:Name"
    values = ["vpc1"]
  }
}

# Get existing private subnets
data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["private*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc1.id]
  }
}

# Get existing hosted zone
data "aws_route53_zone" "devlake" {
  name = "devlake.aws-dev.replace-me.com"
}

# Get existing Aurora MySQL credentials from Secrets Manager
data "aws_secretsmanager_secret" "devlake" {
  name = "devlaked1"
}

data "aws_secretsmanager_secret_version" "devlake" {
  secret_id = data.aws_secretsmanager_secret.devlake.id
}

# Parse the secret JSON
locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)
}

# Get ECR repository data
data "aws_ecr_repository" "devlake" {
  name = split("/", var.devlake_ecr_repo)[1]
}

data "aws_ecr_repository" "grafana" {
  name = split("/", var.grafana_ecr_repo)[1]
}

data "aws_ecr_repository" "config_ui" {
  name = split("/", var.config_ui_ecr_repo)[1]
}

# Validate Aurora MySQL connection
resource "null_resource" "validate_mysql_connection" {
  provisioner "local-exec" {
    command = <<-EOT
      mysql -h ${local.db_credentials.host} \
            -P ${local.db_credentials.port} \
            -u ${local.db_credentials.username} \
            -p${local.db_credentials.password} \
            -e "SELECT 1;" || exit 1
    EOT
  }
}

# Outputs for verification
output "vpc_id" {
  value = data.aws_vpc.vpc1.id
}

output "private_subnet_ids" {
  value = data.aws_subnets.private.ids
}

output "ecr_repositories" {
  value = {
    devlake   = data.aws_ecr_repository.devlake.repository_url
    grafana   = data.aws_ecr_repository.grafana.repository_url
    config_ui = data.aws_ecr_repository.config_ui.repository_url
  }
} 