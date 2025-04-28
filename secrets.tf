# RDS Secrets

resource "aws_secretsmanager_secret" "rds-credentials" {
  name = "psql-rds-credentials"
}

resource "aws_secretsmanager_secret_version" "rds-credentials-value" {
  secret_id     = aws_secretsmanager_secret.rds-credentials.id
  secret_string = jsonencode({
    engine      = "postgres"
    host        = aws_db_instance.django_rds.address
    username    = var.username
    password    = random_password.rds_password.result
    dbname      = var.db_name
    port        = 5432
    
  })
}

resource "aws_secretsmanager_secret" "django-secret" {
  name = "django-secret-key"
}

resource "aws_secretsmanager_secret_version" "django-secret"{
  secret_id     = aws_secretsmanager_secret.django-secret.id
  secret_string =  jsonencode({
    secret_key  = random_password.secret_key.result
  }) 
}

# Read Secrets

data "aws_secretsmanager_secret" "rds_secret" {
  name = "psql-rds-credentials"
}

data "aws_secretsmanager_secret_version" "rds_secret" {
  secret_id = data.aws_secretsmanager_secret.rds_secret.id
}

data "aws_secretsmanager_secret" "django_secret" {
  name = "django-secret-key"
}

data "aws_secretsmanager_secret_version" "django_secret" {
  secret_id = data.aws_secretsmanager_secret.django_secret.id
}
