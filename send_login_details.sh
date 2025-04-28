#!/bin/bash

set -e

# Fetch outputs
ADMIN_URL=$(terraform output -raw admin_panel_credentials)
DB_COMMAND=$(terraform output -raw database_connection_command)

# Prepare message
MESSAGE=$(cat <<EOF
🎉 Your Deployment is Ready!

==== Admin Panel Login ====
$ADMIN_URL

==== Database Connection ====
$DB_COMMAND

Enjoy your service! 🚀
EOF
)

# Publish to SNS
aws sns publish --topic-arn "$1" --subject "Your Django App Login Details" --message "$MESSAGE"