# Setup Guide - Before Deploying

This repository has been sanitized of sensitive data. Follow these steps to set up your local environment.

## Prerequisites

- Terraform >= 1.13
- AWS CLI configured with credentials
- Docker (for local testing)
- Python 3.10+

## Step 1: Create Environment Configuration Files

### For Production

Create `terraform/environments/production/terraform.tfvars`:

```hcl
environment     = "production"
project_name    = "test"
db_password     = "your_production_db_password_here"
enable_cost_governance = true
enable_monitoring = true
```

### For Staging

Create `terraform/environments/staging/terraform.tfvars`:

```hcl
environment     = "staging"
project_name    = "test"
db_password     = "your_staging_db_password_here"
enable_cost_governance = true
enable_monitoring = true
```

## Step 2: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your region (us-east-1)
# Enter default output format (json)
```

## Step 3: Update Terraform State (If Migrating Existing Infrastructure)

Replace placeholder values in configuration files:

- **AWS Account ID**: Replace `123456789012` with your actual AWS Account ID
- **Database Passwords**: Replace `[PROD_PWD]` and `[STAGING_PWD]` with actual passwords
- **Secret ARNs**: Update `test-production-db-password-XXXXX` with actual secret names

## Step 4: Initialize Terraform

```bash
cd terraform
terraform init
```

## Step 5: Review and Plan Changes

```bash
# For production
terraform plan -var-file="environments/production/terraform.tfvars"

# For staging
terraform plan -var-file="environments/staging/terraform.tfvars"
```

## Step 6: Deploy Infrastructure

```bash
# For production
terraform apply -var-file="environments/production/terraform.tfvars"

# For staging
terraform apply -var-file="environments/staging/terraform.tfvars"
```

## Important Security Notes

⚠️ **NEVER commit these files to version control:**
- `terraform/environments/*/terraform.tfvars`
- `.env` files
- AWS credentials files
- Private keys or certificates

✅ **DO commit:**
- `terraform/environments/*/terraform.tfvars.example` (with placeholder values)
- Terraform code (`.tf` files)
- Docker configuration
- Application code

## Application Configuration

The Flask application requires these environment variables:

```bash
DB_HOST=your_rds_endpoint
DB_PORT=5432
DB_NAME=appdb
DB_USER=postgres
DB_PASSWORD=your_db_password
NODE_ENV=production
```

These are managed by the ECS task definition and Secrets Manager.

## Troubleshooting

### Terraform State Out of Sync
```bash
terraform refresh -var-file="environments/production/terraform.tfvars"
```

### Missing Secrets in AWS Secrets Manager
Ensure secrets are created with correct names:
- `test-production-db-password`
- `test-staging-db-password`

### ECS Task Failures
Check CloudWatch logs at `/ecs/test-production` or `/ecs/test-staging`

## Next Steps

1. Update AWS account ID in all configuration files
2. Create database passwords and update Secrets Manager
3. Build and push Docker image to ECR
4. Deploy infrastructure with Terraform
5. Test application endpoints

For more information, see:
- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Task Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
