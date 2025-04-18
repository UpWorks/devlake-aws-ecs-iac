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

# KMS Key Variables
variable "cloudwatch_kms_key_id" {
  description = "KMS key ID for CloudWatch Logs encryption"
  type        = string
}

variable "secrets_kms_key_id" {
  description = "KMS key ID for Secrets Manager encryption"
  type        = string
}

variable "ecr_kms_key_id" {
  description = "KMS key ID for ECR repository encryption"
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
  name = "devlake/devlake"
}

data "aws_ecr_repository" "grafana" {
  name = "devlake-devlake-dashboard"
}

data "aws_ecr_repository" "config_ui" {
  name = "devlake/config-ui"
}

# Validate Aurora MySQL connection

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