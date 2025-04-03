# ECR Repository Configuration
resource "aws_ecr_repository" "devlake" {
  name                 = "devlake/devlake"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.ecr_kms_key_id
  }
}

resource "aws_ecr_repository" "grafana" {
  name                 = "devlake-devlake-dashboard"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.ecr_kms_key_id
  }
}

resource "aws_ecr_repository" "config_ui" {
  name                 = "devlake/config-ui"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.ecr_kms_key_id
  }
} 