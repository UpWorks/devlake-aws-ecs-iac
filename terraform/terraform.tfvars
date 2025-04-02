# AWS Account and Region
aws_account_id = "123456789012"
aws_region     = "us-west-2"

# ECR Repository URLs
devlake_ecr_repo  = "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/devlake"
grafana_ecr_repo   = "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/devlake-grafana"
config_ui_ecr_repo = "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/devlake-config-ui" 