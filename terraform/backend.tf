terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "devlake"
    workspaces {
      name = "devlake-aws-ecs"
    }
  }
}

provider "aws" {
  region = var.aws_region
} 