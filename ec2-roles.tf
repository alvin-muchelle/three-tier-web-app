# For Web EC2s

# 1. Create an IAM Role with SSM Permissions

resource "aws_iam_role" "web_instance_role" {
  name = "web-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# 2. Attach SSM Policy

resource "aws_iam_role_policy_attachment" "web_ssm_policy" {
  role       = aws_iam_role.web_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 3. Create an Instance Profile

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "web-instance-profile"
  role = aws_iam_role.web_instance_role.name
}

# App EC2s

# 1. IAM Role for access to SSM and Secrets Manager

resource "aws_iam_role" "app_instance_role" {
  name = "app-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# 2. SSM policy attachment
resource "aws_iam_role_policy_attachment" "app_ssm_policy" {
  role       = aws_iam_role.app_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 3. Secrets Manager inline policy
resource "aws_iam_policy" "app_secrets_policy" {
  name = "secrets-access"
  description = "Allow app EC2s to fetch RDS and Django secrets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = [
        aws_secretsmanager_secret.rds-credentials.arn,
        aws_secretsmanager_secret.django-secret.arn
      ]
    }]
  })
}

# Secrets Manager policy attachment

resource "aws_iam_role_policy_attachment" "app_secrets_attachment" {
  role       = aws_iam_role.app_instance_role.name
  policy_arn = aws_iam_policy.app_secrets_policy.arn
}

# 4. IAM Instance Profile

resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "app-instance-profile"
  role = aws_iam_role.app_instance_role.name
  
  depends_on = [aws_iam_role_policy_attachment.app_secrets_attachment]
}
