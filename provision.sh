#!/bin/bash
set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: $0 <uat|prod>"
  exit 1
fi

TFVARS="./env/${ENV}.tfvars"
BACKEND="./backend/${ENV}.conf"
PLAN="./backend/${ENV}.tfplan"

if [ ! -f "$TFVARS" ] || [ ! -f "$BACKEND" ]; then
  echo "Missing tfvars or backend config for ${ENV}"
  exit 1
fi

terraform init --backend-config=$BACKEND
terraform validate
terraform plan --var-file=$TFVARS --out=$PLAN
terraform apply $PLAN

APP_PUB_KEY=$(terraform output -raw app_public_key)
APP_PRIV_KEY=$(terraform output -raw app_private_key)
DB_PUB_KEY=$(terraform output -raw db_public_key)
DB_PRIV_KEY=$(terraform output -raw db_private_key)

mkdir -p ./.ssh
echo "$APP_PUB_KEY" > ./.ssh/${ENV}_app_pub
echo "$APP_PRIV_KEY" > ./.ssh/${ENV}_app_priv
echo "$DB_PUB_KEY" > ./.ssh/${ENV}_db_pub
echo "$DB_PRIV_KEY" > ./.ssh/${ENV}_db_priv
chmod -R 600 ./.ssh
