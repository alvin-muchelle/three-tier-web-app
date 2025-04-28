#!/bin/bash

# Create empty Terraform files
touch "./main.tf"
touch "./variables.tf"
touch "./outputs.tf"
touch "./vpc.tf"
touch "./security_groups.tf"
touch "./web.tf"
touch "./app.tf"
touch "./rds.tf"

# Create root and subdirectories
mkdir -p "./user_data"

# Create empty user data scripts
touch "./user_data/web.sh"
touch "./user_data/app.sh"