locals {
  common_tags = {
    Environment = var.environment
    Project     = "devlake"
    ManagedBy   = "terraform"
    Owner       = "platform-team"
    CostCenter  = "platform"
  }
}

# Route53 Records
resource "aws_route53_record" "devlake" {
  zone_id = var.hosted_zone_id
  name    = "devlake.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = var.hosted_zone_id
  name    = "grafana.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "config_ui" {
  zone_id = var.hosted_zone_id
  name    = "config.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
} 