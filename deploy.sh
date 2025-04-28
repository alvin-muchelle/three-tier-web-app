#!/bin/bash

set -e  # exit immediately if a command exits with non-zero
set -o pipefail

echo "🚀 Starting deployment..."

# 1. Fetch current public IP
MY_IP=$(curl -s https://checkip.amazonaws.com)

if [[ -z "$MY_IP" ]]; then
  echo "❌ Failed to fetch public IP. Check internet connection."
  exit 1
fi

CIDR="$MY_IP/32"
echo "🌐 Your public IP detected as: $CIDR"

export TF_VAR_my_ip_cidr="${CIDR}"

# 2. Read email address
read -p "📧 Enter notification email address: " NOTIFICATION_EMAIL
export TF_VAR_notification_email="$NOTIFICATION_EMAIL"

# 3. Get the default AWS region and AZs
AWS_REGION=$(aws configure get region)
if [[ -z "$AWS_REGION" ]]; then
  echo "❌ No AWS region configured. Please configure your AWS CLI region."
  exit 1
fi
echo "🌍 AWS Region detected: $AWS_REGION"

export TF_VAR_aws_region="$AWS_REGION"

AZ1=$(aws ec2 describe-availability-zones --region "$AWS_REGION" --query "AvailabilityZones[0].ZoneName" --output text)
export TF_VAR_az_1="$AZ1"

AZ2=$(aws ec2 describe-availability-zones --region "$AWS_REGION" --query "AvailabilityZones[1].ZoneName" --output text)
export TF_VAR_az_2="$AZ2"

echo "Designated AZs are $AZ1 and $AZ2"

# 4. Define Secrets
RDS_SECRET_NAME="psql-rds-credentials"
DJANGO_SECRET_NAME="django-secret-key"

# 5. Check/Create RDS Secret
if aws secretsmanager describe-secret --secret-id "$RDS_SECRET_NAME" >/dev/null 2>&1; then
  echo "🔎 RDS Secret '$RDS_SECRET_NAME' already exists."
else
  echo "⚡ Creating RDS Secret '$RDS_SECRET_NAME'..."
  aws secretsmanager create-secret --name "$RDS_SECRET_NAME" --secret-string '{
    "dbname": "employees_db",
    "username": "john_doe",
    "password": "SuperStrongPassword123!",
    "host": "replace-this-after-db-creation"
  }'
fi

# 6. Check/Create Django Secret
if aws secretsmanager describe-secret --secret-id "$DJANGO_SECRET_NAME" >/dev/null 2>&1; then
  echo "🔎 Django Secret '$DJANGO_SECRET_NAME' already exists."
else
  echo "⚡ Creating Django Secret '$DJANGO_SECRET_NAME'..."
  RANDOM_SECRET=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9!@#$%^&*()-_=+[]{}|;:,.<>?')
  aws secretsmanager create-secret --name "$DJANGO_SECRET_NAME" --secret-string "{
    \"secret_key\": \"${RANDOM_SECRET}\"
  }"
fi

# 7. Terraform Deploy
echo "📦 Running Terraform commands..."

# Create VPC
terraform apply -target=aws_subnet.public -target=aws_subnet.private -target=aws_subnet.db_private --auto-approve

# Fetch Secret ARNs
PSQL_SECRET_ARN=$(aws secretsmanager list-secrets --query "SecretList[?Name=='psql-rds-credentials'].ARN" --output text)
DJANGO_SECRET_ARN=$(aws secretsmanager list-secrets --query "SecretList[?Name=='django-secret-key'].ARN" --output text)

# Import secrets
terraform import aws_secretsmanager_secret.rds-credentials "${PSQL_SECRET_ARN}"
terraform import aws_secretsmanager_secret.django-secret "${DJANGO_SECRET_ARN}"

# Initialize terraform and apply
terraform init
terraform plan
terraform apply --auto-approve

echo "✅ Deployment Complete!"