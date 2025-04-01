terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"  # Replace with your desired region
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