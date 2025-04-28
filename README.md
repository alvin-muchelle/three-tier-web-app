Project Overview
Deploy a Django Admin web application on AWS using Terraform.

Architecture
Web Tier: External Application Load Balancer (ALB) routing to Web EC2 instances in an Auto Scaling Group (ASG)

App Tier: Internal ALB routing from Web EC2s to an ASG of Django App EC2 instances.

Database Tier: Amazon RDS PostgreSQL instances

Secrets Management: AWS Secrets Manager for securely storing DB credentials and Django secret key

Logging: Admin and database login credentials securely captured and output

Notifications: Amazon SNS sends the login information via email


Features
Full Infrastructure as Code using Terraform

Dynamic secrets creation if they don't exist already

Auto-fetch RDS Database secrets and Django Secret Key at EC2 instance boot time

Django Admin Panel preloaded with a Superuser account

Secure password generation and management

Rolling deployments through Auto Scaling Groups

Automated Django database migrations

Static files collection handled automatically

Application health monitored using ALB health checks


📁 Folder Structure
.
├── README.md                    # Project documentation (this file)
├── deploy.sh                     # Full deployment wrapper script
├── setup.sh                      # Initial folder setup script
├── send_login_details.sh         # Script to send credentials via SNS
├── main.tf                       # Root Terraform config
├── app.tf                        # App Tier resources (App ALB, ASG, Launch Template)
├── web.tf                        # Web Tier resources (Web ALB, Web EC2)
├── rds.tf                        # Database Tier (RDS PostgreSQL)
├── vpc.tf                        # VPC and Subnets setup
├── security_groups.tf            # Security Groups for all tiers
├── ec2-roles.tf                  # IAM Roles and Instance Profiles
├── lamda-role.tf                 # (Optional) Lambda IAM Role (for future extension)
├── sns-topic.tf                  # SNS Topic and Subscription for notifications
├── send-login-details.tf         # Lambda & IAM setup to send email notifications
├── secrets.tf                    # Secrets Manager resources (RDS and Django secrets)
├── patch_secret.tf               # Patch RDS secret with dynamic DB host
├── outputs-app-login.tf          # Outputs for Admin Panel and Database Login
├── locals.tf                     # Local variables for public and private subnets
├── variables.tf                  # Input variables
├── user_data/                    # EC2 User Data scripts
│   ├── app.sh                    # App EC2 bootstrap script (Django + Gunicorn)
│   └── web.sh                    # Web EC2 bootstrap script (Nginx)


How to Deploy

1. Clone this repository

git clone <link to this repo>
cd your-repo

2. Prepare your environment

Install Terraform
Install and configure the AWS CLI

3. Run the Deployment Script

chmod +x deploy.sh
./deploy.sh
You will be prompted to enter:

Your email address to receive login details (via SNS)

4. Wait for Infrastructure to Deploy

Terraform will automatically:
    Create all required resources
    Set up secrets
    Launch EC2 instances
    Initialize your Django application
    Send Admin login details to your email via SNS

5. Access the Application

Open the External ALB DNS:
http://<external-alb-dns>/admin/

6. Login using the credentials emailed to you.


Technologies Used

Amazon EC2 (Elastic Compute Cloud) running on Amazon Linux 2

Amazon ALB (Application Load Balancer)

Amazon ASG (Auto Scaling Group)

Amazon RDS for PostgreSQL

AWS Secrets Manager

AWS IAM (Identity and Access Management)

Amazon SNS (Simple Notification Service)

Terraform (Infrastructure as Code)

Django (Python Web Framework)

Gunicorn (Python WSGI HTTP Server)

Nginx (Web Server and Gunicorn Proxy)
