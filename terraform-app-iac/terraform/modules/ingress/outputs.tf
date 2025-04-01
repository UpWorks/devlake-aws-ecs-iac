output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.devlake.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.devlake.zone_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "devlake_target_group_arn" {
  description = "ARN of the DevLake target group"
  value       = aws_lb_target_group.devlake.arn
}

output "grafana_target_group_arn" {
  description = "ARN of the Grafana target group"
  value       = aws_lb_target_group.grafana.arn
}

output "config_ui_target_group_arn" {
  description = "ARN of the Config UI target group"
  value       = aws_lb_target_group.config_ui.arn
} 