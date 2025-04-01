# Apache DevLake AWS ECS App Infrastructure

This directory contains the Terraform configuration for deploying the Apache DevLake application infrastructure on AWS ECS Fargate. This configuration is separate from the base infrastructure and focuses on the application-specific resources.

## Directory Structure

```
terraform/
├── config/
│   └── dev/
│       └── devlake-d1.auto.tfvars    # Dev environment configuration
├── modules/
│   ├── container-definitions/        # ECS task container definitions
│   ├── ecs/                         # ECS cluster and services
│   └── ingress/                     # ALB and target groups
├── backend.tf                       # Terraform backend configuration
├── main.tf                          # Main configuration file
├── variables.tf                     # Input variables
└── outputs.tf                       # Output values
```

## Prerequisites

1. Base infrastructure must be deployed first (VPC, subnets, etc.)
2. AWS Secrets Manager secret containing database credentials
3. ACM certificate for HTTPS
4. IAM roles for ECS tasks and execution
5. Security group for ECS tasks

## Required Variables

- `aws_region`: AWS region to deploy resources
- `environment`: Environment name (dev, staging, prod)
- `vpc_name`: Name of the existing VPC
- `private_subnet_name_prefix`: Prefix for private subnet names
- `public_subnet_name_prefix`: Prefix for public subnet names
- `hosted_zone_name`: Name of the Route53 hosted zone
- `secret_name`: Name of the AWS Secrets Manager secret
- `acm_certificate_arn`: ARN of the ACM certificate
- `ecs_execution_role_arn`: ARN of the ECS execution role
- `ecs_task_role_arn`: ARN of the ECS task role
- `ecs_tasks_security_group_id`: ID of the security group for ECS tasks

## Optional Variables

- `container_ports`: Map of container ports for each service
- `container_resources`: Resource configurations for containers
- `devlake_image`: Docker image for DevLake service
- `grafana_image`: Docker image for Grafana service
- `config_ui_image`: Docker image for Config UI service
- `desired_count`: Desired number of tasks to run
- `log_retention_days`: Number of days to retain CloudWatch logs

## Deployment

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan -var-file="config/dev/devlake-d1.auto.tfvars"
   ```

3. Apply the configuration:
   ```bash
   terraform apply -var-file="config/dev/devlake-d1.auto.tfvars"
   ```

## Outputs

- `devlake_service_url`: URL for the DevLake service
- `grafana_service_url`: URL for the Grafana service
- `config_ui_service_url`: URL for the Config UI service
- `ecs_cluster_id`: ID of the ECS cluster
- `ecs_cluster_arn`: ARN of the ECS cluster
- `devlake_service_name`: Name of the DevLake service
- `grafana_service_name`: Name of the Grafana service
- `config_ui_service_name`: Name of the Config UI service
- `alb_dns_name`: DNS name of the Application Load Balancer
- `alb_zone_id`: Zone ID of the Application Load Balancer

## Security Considerations

1. All services are deployed in private subnets
2. HTTPS is enforced through ACM certificate
3. Secrets are managed through AWS Secrets Manager
4. IAM roles follow the principle of least privilege
5. Security groups restrict access to necessary ports only

## Maintenance

1. Monitor CloudWatch logs for application issues
2. Review ECS service metrics for performance
3. Update container images as new versions are released
4. Regularly rotate secrets and certificates
5. Review and update security group rules as needed 