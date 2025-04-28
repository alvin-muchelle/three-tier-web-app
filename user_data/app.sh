#!/bin/bash

# Update system and install required dependencies
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y amazon-linux-extras gcc openssl-devel bzip2-devel libffi-devel wget make zlib-devel nc jq

# Install PostgreSQL Client
sudo amazon-linux-extras enable postgresql13
sudo yum clean metadata
sudo yum install -y postgresql

# Install Python 3.8.18 from source
cd /usr/src
sudo wget https://www.python.org/ftp/python/3.8.18/Python-3.8.18.tgz
sudo tar xzf Python-3.8.18.tgz
cd Python-3.8.18
sudo ./configure --enable-optimizations
sudo make altinstall

# Install virtualenv
sudo /usr/local/bin/python3.8 -m pip install --upgrade pip
sudo /usr/local/bin/python3.8 -m pip install virtualenv

# Set up project directory and virtual environment
cd /home/ec2-user
mkdir -p employee_management
cd employee_management

# Create a virtual environment
python3.8 -m venv venv
source venv/bin/activate

# Upgrade pip inside virtual environment
pip install --upgrade pip

# Install required Python dependencies
pip install django gunicorn psycopg2-binary python-dotenv

# Fetch secrets
export AWS_REGION="${region}"

{
# Fetch RDS secret
RDS_SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id psql-rds-credentials --query SecretString --region "$AWS_REGION" --output text 2>/dev/null)
echo "RDS_SECRET_JSON=$RDS_SECRET_JSON"

# Fetch Django secret
DJANGO_SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id django-secret-key --query SecretString --region "$AWS_REGION" --output text 2>/dev/null)
echo "DJANGO_SECRET_JSON=$DJANGO_SECRET_JSON"

# Extract fields safely
DB_NAME=$(echo "$RDS_SECRET_JSON" | jq -r .dbname)
DB_USER=$(echo "$RDS_SECRET_JSON" | jq -r .username)
DB_PASSWORD=$(echo "$RDS_SECRET_JSON" | jq -r .password)
DB_HOST=$(echo "$RDS_SECRET_JSON" | jq -r .host)
SECRET_KEY=$(echo "$DJANGO_SECRET_JSON" | jq -r .secret_key)

# Export DB credentials as environment variables for later use
export DB_USER
export DB_PASSWORD
export DB_NAME
export DB_HOST
export SECRET_KEY

# Write to .env
sudo touch /home/ec2-user/employee_management/.env
sudo chown ec2-user:ec2-user /home/ec2-user/employee_management/.env
sudo chmod 600 /home/ec2-user/employee_management/.env

{
echo "DB_NAME=$DB_NAME"
echo "DB_USER=$DB_USER"
echo "DB_PASSWORD=$DB_PASSWORD"
echo "DB_HOST=$DB_HOST"
echo "SECRET_KEY=$SECRET_KEY"
} > /home/ec2-user/employee_management/.env

}

# Export notification email as an environment variable
export email="${notification_email}"

# Create Django project
django-admin startproject employee_management .
python manage.py startapp employees

# Create templates directory
mkdir -p employees/templates/employees

# Overwrite settings.py with DB and secret key
sudo tee > employee_management/settings.py <<EOF
import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

load_dotenv(os.path.join(BASE_DIR, '.env'))

SECRET_KEY = os.environ.get("SECRET_KEY")
DEBUG = True
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'employees',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]

ROOT_URLCONF = 'employee_management.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'employee_management.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get("DB_NAME"),
        'USER': os.environ.get("DB_USER"),
        'PASSWORD': os.environ.get("DB_PASSWORD"),
        'HOST': os.environ.get("DB_HOST"),
        'PORT': '5432',
    }
}

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static')
EOF

# Create a simple view
sudo tee > employees/views.py <<EOF
from django.http import HttpResponse

def home(request):
    return HttpResponse("Hello from the App Tier!")

def health_check(request):
    return HttpResponse("OK", status=200)
EOF

# URL routing
sudo tee > employee_management/urls.py <<EOF
from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from employees.views import home, health_check

urlpatterns = [
    path('', home),
    path('health/', health_check),
    path('admin/', admin.site.urls),
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
EOF

# Django setup
python manage.py migrate
python manage.py collectstatic --noinput

# Create Django superuser
export DJANGO_SUPERUSER_USERNAME="$DB_USER"
export DJANGO_SUPERUSER_PASSWORD="$DB_PASSWORD"

python manage.py shell <<EOF
from django.contrib.auth.models import User
if not User.objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists():
    User.objects.create_superuser(
        username='$DJANGO_SUPERUSER_USERNAME',
        password='$DJANGO_SUPERUSER_PASSWORD',
        first_name='Django',
        last_name='Admin',
        email='$email'
    )
    print("Django superuser '$DJANGO_SUPERUSER_USERNAME' created successfully.")
else:
    print("Django superuser '$DJANGO_SUPERUSER_USERNAME' already exists.")
EOF

# Gunicorn systemd service
sudo tee > /etc/systemd/system/gunicorn.service <<EOF
[Unit]
Description=Gunicorn daemon for Django app
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/employee_management
ExecStart=/home/ec2-user/employee_management/venv/bin/gunicorn --bind 0.0.0.0:8000 employee_management.wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Fix permissions and start Gunicorn
sudo chown -R ec2-user:ec2-user /home/ec2-user/employee_management
sudo chmod -R 755 /home/ec2-user/employee_management

# Reload systemd, enable, and start Gunicorn
sudo systemctl daemon-reexec
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

