output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.devlake.name
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.devlake.arn
}

output "devlake_service_name" {
  description = "The name of the DevLake service"
  value       = aws_ecs_service.devlake.name
}

output "grafana_service_name" {
  description = "The name of the Grafana service"
  value       = aws_ecs_service.grafana.name
}

output "config_ui_service_name" {
  description = "The name of the Config UI service"
  value       = aws_ecs_service.config_ui.name
}

output "devlake_task_definition_arn" {
  description = "The ARN of the DevLake task definition"
  value       = aws_ecs_task_definition.devlake.arn
}

output "grafana_task_definition_arn" {
  description = "The ARN of the Grafana task definition"
  value       = aws_ecs_task_definition.grafana.arn
}

output "config_ui_task_definition_arn" {
  description = "The ARN of the Config UI task definition"
  value       = aws_ecs_task_definition.config_ui.arn
}

output "cloudwatch_log_groups" {
  description = "The CloudWatch log groups created"
  value = {
    devlake   = aws_cloudwatch_log_group.devlake.name
    grafana   = aws_cloudwatch_log_group.grafana.name
    config_ui = aws_cloudwatch_log_group.config_ui.name
  }
} 