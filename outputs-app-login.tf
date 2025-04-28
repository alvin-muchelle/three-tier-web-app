output "admin_panel_credentials" {
  description = "Login credentials for Django Admin Panel"
  sensitive = true
  value = <<EOT
🌐 Admin Panel URL: http://${aws_lb.web-tier-alb.dns_name}/admin/
📧 Email: ${var.notification_email}
👤 Username: ${var.username}
🔑 Password: ${jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["password"]}
EOT

  depends_on = [ 
    aws_lb.web-tier-alb,
    aws_secretsmanager_secret_version.rds-credentials-value 
  ]
  
}

output "database_connection_command" {
  description = "psql command to connect to the RDS database"
  sensitive = true
  value = <<EOT
psql -h ${aws_db_instance.django_rds.address} -U ${jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["username"]} -d ${jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["dbname"]}
EOT
}

output "topic_arn" {
  value = aws_sns_topic.login_topic.arn
  sensitive = true
}