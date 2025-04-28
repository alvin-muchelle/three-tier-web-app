# VPC Architecture variables

variable "aws_region" {
  type = string
}

variable "az_1" {
  type = string
}

variable "az_2" {
  type = string
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_private_subnet_cidrs" {
  default = ["10.0.16.0/22", "10.0.20.0/22"]
}

variable "db_private_subnet_cidrs" {
  default = ["10.0.32.0/23", "10.0.34.0/23"]
}


# Web and App ASG variables

variable "instance_count" {
  default = 1
}

variable "desired_capacity" {
  default = 1
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 1
}

variable "ami_id" {
  default = "ami-09087811a4a9de6c1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = "main-key"
}

# App Tier Variables

variable "db_name" {
  default = "employees_db"
}

variable "username" {
  default = "django_admin"
}

variable "my_ip_cidr" {
  description = "The public IP CIDR for accessing RDS from local machine"
  type        = string
}

# DB Variables

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_engine_version" {
  default = "17.4"
}

# SNS Variable

variable "notification_email" {
  description = "Email address to send login details to"
  type        = string
}
