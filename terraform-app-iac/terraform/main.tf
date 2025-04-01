data "aws_vpc" "vpc1" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${var.private_subnet_name_prefix}*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc1.id]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["${var.public_subnet_name_prefix}*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc1.id]
  }
}

data "aws_route53_zone" "devlake" {
  name = var.hosted_zone_name
}

data "aws_secretsmanager_secret" "devlake" {
  name = var.secret_name
}

data "aws_secretsmanager_secret_version" "devlake" {
  secret_id = data.aws_secretsmanager_secret.devlake.id
}

data "aws_caller_identity" "current" {}

module "ecs" {
  source = "./modules/ecs"

  environment                = var.environment
  aws_region               = var.aws_region
  private_subnet_ids       = data.aws_subnets.private.ids
  ecs_tasks_security_group_id = var.ecs_tasks_security_group_id
  container_ports          = var.container_ports
  container_resources      = var.container_resources
  ecs_execution_role_arn   = var.ecs_execution_role_arn
  ecs_task_role_arn       = var.ecs_task_role_arn
  hosted_zone_name        = var.hosted_zone_name
  devlake_image          = var.devlake_image
  grafana_image          = var.grafana_image
  config_ui_image        = var.config_ui_image
  db_username            = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["username"]
  db_password            = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["password"]
  db_host                = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["host"]
  db_port                = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["port"]
  db_name                = jsondecode(data.aws_secretsmanager_secret_version.devlake.secret_string)["database"]
  devlake_target_group_arn = module.ingress.devlake_target_group_arn
  grafana_target_group_arn = module.ingress.grafana_target_group_arn
  config_ui_target_group_arn = module.ingress.config_ui_target_group_arn
  desired_count          = var.desired_count
  log_retention_days     = var.log_retention_days
}

module "ingress" {
  source = "./modules/ingress"

  environment         = var.environment
  vpc_id             = data.aws_vpc.vpc1.id
  public_subnet_ids  = data.aws_subnets.public.ids
  hosted_zone_name   = var.hosted_zone_name
  acm_certificate_arn = var.acm_certificate_arn
  container_ports    = var.container_ports
} 