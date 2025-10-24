#!/bin/bash
set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: $0 <uat|prod>"
  exit 1
fi

TFVARS="./env/${ENV}.tfvars"
BACKEND="./backend/${ENV}.conf"

if [ ! -f "$TFVARS" ] || [ ! -f "$BACKEND" ]; then
  echo "Missing tfvars or backend config for ${ENV}"
  exit 1
fi

terraform init --backend-config=$BACKEND
terraform destroy --var-file=$TFVARS
