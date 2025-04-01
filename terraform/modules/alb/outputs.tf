output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.devlake.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.devlake.zone_id
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.devlake.arn
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "devlake_target_group_arn" {
  description = "The ARN of the DevLake target group"
  value       = aws_lb_target_group.devlake.arn
}

output "grafana_target_group_arn" {
  description = "The ARN of the Grafana target group"
  value       = aws_lb_target_group.grafana.arn
}

output "config_ui_target_group_arn" {
  description = "The ARN of the Config UI target group"
  value       = aws_lb_target_group.config_ui.arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  value       = aws_lb_listener.devlake_https.arn
} 