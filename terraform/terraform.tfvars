# AWS Account and Region
aws_account_id = "123456789012"
aws_region     = "us-west-2"

# KMS Key IDs
cloudwatch_kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/your-cloudwatch-key-id"
secrets_kms_key_id    = "arn:aws:kms:us-west-2:123456789012:key/your-secrets-key-id"
ecr_kms_key_id       = "arn:aws:kms:us-west-2:123456789012:key/your-ecr-key-id"

# ECR Repository URLs
devlake_ecr_repo   = "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/devlake/devlake"
grafana_ecr_repo   = "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/devlake-devlake-dashboard"
config_ui_ecr_repo = "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/devlake/config-ui" 