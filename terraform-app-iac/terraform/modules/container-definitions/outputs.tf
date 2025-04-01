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