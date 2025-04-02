terraform {
  required_version = ">=1.0.10"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "your-org-name"

    workspaces {
      name = "devlake-ecs"
    }
  }
} 