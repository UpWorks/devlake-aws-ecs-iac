output "devlake_service_url" {
  description = "URL for the DevLake service"
  value       = "https://devlake.${var.hosted_zone_name}"
}

output "grafana_service_url" {
  description = "URL for the Grafana service"
  value       = "https://grafana.${var.hosted_zone_name}"
}

output "config_ui_service_url" {
  description = "URL for the Config UI service"
  value       = "https://config.${var.hosted_zone_name}"
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "devlake_service_name" {
  description = "Name of the DevLake service"
  value       = module.ecs.devlake_service_name
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = module.ecs.grafana_service_name
}

output "config_ui_service_name" {
  description = "Name of the Config UI service"
  value       = module.ecs.config_ui_service_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ingress.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.ingress.alb_zone_id
} 