# 1. Create RDS  Group for Private Subnet

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [for subnet in aws_subnet.db_private : subnet.id]
  tags = {
    Name = "RDS subnet group"
  }
}

# 2. Generate Random Password and Secret Key for RDS

resource "random_password" "rds_password" {
  length  = 16
  special = false
}

resource "random_password" "secret_key" {
  length  = 64
  special = true
}

# 3. Create RDS PostgreSQL Database

resource "aws_db_instance" "django_rds" {
  identifier              = "django-postgres-db"
  engine                  = "postgres"
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  username                = var.username
  password                = random_password.rds_password.result
  db_name                 = var.db_name
  port                    = 5432
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  skip_final_snapshot     = true
  storage_encrypted       = true
  multi_az                = false
  iam_database_authentication_enabled = true

  depends_on = [aws_db_subnet_group.rds_subnet_group]
}