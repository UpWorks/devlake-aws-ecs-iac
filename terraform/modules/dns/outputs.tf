output "devlake_fqdn" {
  description = "The FQDN of the DevLake service"
  value       = aws_route53_record.devlake.fqdn
}

output "grafana_fqdn" {
  description = "The FQDN of the Grafana service"
  value       = aws_route53_record.grafana.fqdn
}

output "config_ui_fqdn" {
  description = "The FQDN of the Config UI service"
  value       = aws_route53_record.config_ui.fqdn
} 