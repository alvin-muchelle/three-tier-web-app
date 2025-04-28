resource "null_resource" "update_rds_secret" {
  depends_on = [aws_db_instance.django_rds]

  provisioner "local-exec" {
    command = <<EOT

DB_INSTANCE_ID="django-postgres-db"
aws rds wait db-instance-available --db-instance-identifier "$DB_INSTANCE_ID"
RDS_HOST=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)

UPDATED_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "psql-rds-credentials" \
  --query SecretString \
  --output text | jq --arg host "$RDS_HOST" '.host = $host')

aws secretsmanager put-secret-value \
  --secret-id "psql-rds-credentials" \
  --secret-string "$UPDATED_SECRET"
EOT
  }
}
