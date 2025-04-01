# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "devlake" {
  name              = "/ecs/devlake"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/grafana"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "config_ui" {
  name              = "/ecs/config-ui"
  retention_in_days = 30
}

# Route53 DNS Records
resource "aws_route53_record" "devlake" {
  zone_id = data.aws_route53_zone.devlake.zone_id
  name    = "devlake.${data.aws_route53_zone.devlake.name}"
  type    = "A"

  alias {
    name                   = aws_lb.devlake.dns_name
    zone_id               = aws_lb.devlake.zone_id
    evaluate_target_health = true
  }
}

# Outputs
output "devlake_url" {
  value = "http://${aws_route53_record.devlake.name}"
}

output "grafana_url" {
  value = "http://${aws_route53_record.devlake.name}/grafana"
}

output "config_ui_url" {
  value = "http://${aws_route53_record.devlake.name}"
} 