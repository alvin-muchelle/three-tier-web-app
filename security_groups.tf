# 1. Create Web App and External ALB Security Group, allowing ports 22, 80, 443.

resource "aws_security_group" "web_sg" {
  name        = "Allow TLS"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Allow TLS traffic"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4_traffic" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 2. Security Group for Internal ALB, receiving traffic from EC2 Nginx SG
resource "aws_security_group" "app_alb_sg" {
  name        = "app-alb-sg"
  description = "Allow traffic from web tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP from Web Tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App ALB SG"
  }
}

# 3. App EC2 Security Group
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow HTTP from internal ALB and SSH from your IP"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "App EC2 SG"
  }
}

# Allow traffic from the internal ALB (on port 8000)
resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
  description       = "Allow HTTP from Internal ALB"
  security_group_id = aws_security_group.app_sg.id
  referenced_security_group_id = aws_security_group.app_alb_sg.id
}

# Allow SSH from your IP
resource "aws_vpc_security_group_ingress_rule" "app_ssh" {
  security_group_id = aws_security_group.app_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip_cidr
  description       = "Allow SSH from my IP"
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "app_allow_all" {
  security_group_id = aws_security_group.app_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Create RDS Security Group for PostgreSQL access

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL access from EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = [var.my_ip_cidr]
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}