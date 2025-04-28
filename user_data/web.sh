#!/bin/bash

# Install Nginx
sudo yum update -y
sudo amazon-linux-extras install -y nginx1
sudo systemctl enable nginx
sudo systemctl start nginx

# Write Nginx reverse proxy config
cat > /etc/nginx/conf.d/reverse-proxy.conf <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://${internal_alb_dns};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Restart Nginx to load config
sudo systemctl restart nginx
