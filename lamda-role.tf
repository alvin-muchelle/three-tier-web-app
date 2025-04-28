# SecretsManagerRDSPostgreSQLRotationSingleUser blueprint

resource "aws_serverlessapplicationrepository_cloudformation_stack" "rotation_lambda_stack" {
  name            = "rds-postgres-rotation-stack-v2"
  application_id  = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationSingleUser"
  semantic_version = "1.1.305"

  parameters = {
    functionName        = "rds-password-rotation-lambda"
    endpoint            = aws_db_instance.django_rds.address
    vpcSubnetIds        = join(",", [for subnet in aws_subnet.db_private : subnet.id])
    vpcSecurityGroupIds = join(",", [aws_security_group.app_sg.id])
  }

  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_RESOURCE_POLICY"
  ]
}

# Connect Lambda to secret

resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  secret_id           = aws_secretsmanager_secret.rds-credentials.id
  rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.rotation_lambda_stack.outputs["RotationLambdaARN"]

depends_on = [ aws_serverlessapplicationrepository_cloudformation_stack.rotation_lambda_stack ]

  rotation_rules {
    automatically_after_days = 30
  }
}
