output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.devlake.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.devlake.arn
}

output "devlake_service_name" {
  description = "Name of the DevLake service"
  value       = aws_ecs_service.devlake.name
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = aws_ecs_service.grafana.name
}

output "config_ui_service_name" {
  description = "Name of the Config UI service"
  value       = aws_ecs_service.config_ui.name
}

output "devlake_task_definition_arn" {
  description = "ARN of the DevLake task definition"
  value       = aws_ecs_task_definition.devlake.arn
}

output "grafana_task_definition_arn" {
  description = "ARN of the Grafana task definition"
  value       = aws_ecs_task_definition.grafana.arn
}

output "config_ui_task_definition_arn" {
  description = "ARN of the Config UI task definition"
  value       = aws_ecs_task_definition.config_ui.arn
}

output "devlake_log_group_name" {
  description = "Name of the DevLake CloudWatch log group"
  value       = aws_cloudwatch_log_group.devlake.name
}

output "grafana_log_group_name" {
  description = "Name of the Grafana CloudWatch log group"
  value       = aws_cloudwatch_log_group.grafana.name
}

output "config_ui_log_group_name" {
  description = "Name of the Config UI CloudWatch log group"
  value       = aws_cloudwatch_log_group.config_ui.name
} 