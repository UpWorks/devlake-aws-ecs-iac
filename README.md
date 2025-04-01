# Apache DevLake AWS ECS Infrastructure

This repository contains the Infrastructure as Code (IaC) for deploying Apache DevLake on AWS ECS Fargate. The infrastructure is designed to be modular, scalable, and follows AWS best practices.

## Architecture Overview

The solution deploys Apache DevLake and its components (Grafana and Config UI) on AWS ECS Fargate with the following architecture:

- **ECS Fargate Cluster**: Runs the containerized applications
- **Application Load Balancer**: Handles traffic distribution and SSL termination
- **Route53**: Manages DNS records for the services
- **CloudWatch**: Handles logging and monitoring
- **Secrets Manager**: Securely stores sensitive information
- **Security Groups**: Controls network access
- **IAM Roles**: Manages permissions for ECS tasks

## Folder Structure

```
terraform/
├── backend.tf           # TFE backend configuration
├── main.tf             # Main Terraform configuration
├── variables.tf        # Variable definitions
├── modules/           # Reusable modules
│   ├── ecs/          # ECS cluster, services, and task definitions
│   ├── alb/          # Application Load Balancer and target groups
│   ├── security/     # Security groups and IAM roles
│   └── dns/          # Route53 DNS records
└── config/
    └── dev/          # Development environment variables
        └── devlake-d1.auto.tfvars
```

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- Terraform Cloud account and workspace
- Existing VPC with private subnets
- Route53 hosted zone
- ACM certificate for HTTPS
- AWS Secrets Manager secret containing database credentials

## Required AWS Resources

Before deploying, ensure you have:

1. **VPC and Networking**:
   - VPC with private subnets
   - Internet Gateway
   - NAT Gateway
   - Route tables

2. **DNS**:
   - Route53 hosted zone
   - ACM certificate for HTTPS

3. **Security**:
   - AWS Secrets Manager secret with database credentials
   - IAM roles and policies

## Configuration

1. **Terraform Cloud Setup**:
   - Create a new workspace in Terraform Cloud
   - Configure the workspace with the following variables:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `TF_VAR_aws_region`
     - `TF_VAR_environment`
     - `TF_VAR_vpc_name`
     - `TF_VAR_private_subnet_name_prefix`
     - `TF_VAR_hosted_zone_name`
     - `TF_VAR_secret_name`
     - `TF_VAR_acm_certificate_arn`

2. **Environment Variables**:
   Update `config/dev/devlake-d1.auto.tfvars` with your environment-specific values:

   ```hcl
   aws_region = "us-west-2"
   environment = "dev"
   vpc_name = "vpc1"
   private_subnet_name_prefix = "private"
   hosted_zone_name = "devlake.aws-dev.replace-me.com"
   secret_name = "devlaked1"
   acm_certificate_arn = "arn:aws:acm:region:account:certificate/certificate-id"
   ```

## Deployment

1. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

2. **Plan the Changes**:
   ```bash
   terraform plan
   ```

3. **Apply the Changes**:
   ```bash
   terraform apply
   ```

## Services

The infrastructure deploys three main services:

1. **DevLake Core**:
   - Port: 8080
   - Health check: `/ping`
   - Endpoint: `https://devlake.your-domain.com`

2. **Grafana Dashboard**:
   - Port: 3000
   - Health check: `/api/health`
   - Endpoint: `https://grafana.your-domain.com`

3. **Config UI**:
   - Port: 4000
   - Health check: `/`
   - Endpoint: `https://config.your-domain.com`

## Security

- All services run in private subnets
- HTTPS is enforced with automatic HTTP to HTTPS redirection
- Security groups restrict access to necessary ports only
- Secrets are managed through AWS Secrets Manager
- IAM roles follow the principle of least privilege

## Monitoring and Logging

- CloudWatch Log Groups for each service
- Container Insights enabled on the ECS cluster
- Health checks configured for all services
- Log retention period: 30 days (configurable)

## Maintenance

### Updating Container Images

To update container images:

1. Update the image tags in the ECS task definitions
2. Apply the Terraform changes
3. ECS will automatically deploy the new images

### Scaling

The infrastructure supports horizontal scaling through the `desired_count` variable in the ECS services.

### Backup and Recovery

- Database backups should be configured separately
- ECS task definitions are versioned
- Route53 records can be restored from Terraform state

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: This will delete all resources. Ensure you have backups of any important data before proceeding.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details. 
