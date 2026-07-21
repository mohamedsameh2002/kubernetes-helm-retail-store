#!/bin/bash

set -e
echo "--------------------------------------------"
echo "Authenticating to Amazon Public ECR for Helm..."
echo "--------------------------------------------"

# Authenticate to Amazon Public ECR (token valid for 12 hours)
aws ecr-public get-login-password --region us-east-1 | \
helm registry login -u AWS --password-stdin public.ecr.aws
sleep 5

echo "--------------------------------------------"
echo "Starting Helm installs for Retail Store Sample App..."
echo "--------------------------------------------"
echo

# Step 01 - Catalog Service
echo "--------------------------------------------"
echo "Installing Catalog Service..."
helm install catalog oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart \
  --version 1.3.0 \
  -f values-catalog.yaml
sleep 10

# Step 02 - Cart Service
echo "--------------------------------------------"
echo "Installing Cart Service..."
helm install cart oci://public.ecr.aws/aws-containers/retail-store-sample-cart-chart \
  --version 1.3.0 \
  -f values-cart.yaml
sleep 10

# Step 03 - Checkout Service
echo "--------------------------------------------"
echo "Installing Checkout Service..."
helm install checkout \
  oci://public.ecr.aws/aws-containers/retail-store-sample-checkout-chart \
  --version 1.3.0 \
  -f values-checkout.yaml
sleep 10

# Step 04 - Orders Service
echo "--------------------------------------------"
echo "Installing Orders Service..."
helm install orders oci://public.ecr.aws/aws-containers/retail-store-sample-orders-chart \
  --version 1.3.0 \
  -f values-orders.yaml
sleep 10


# Step 05 - UI Service
echo "--------------------------------------------"
echo "Installing UI Service..."
helm install ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.3.0 \
  -f values-ui.yaml
sleep 10

echo
echo "--------------------------------------------"
echo "All Helm installs completed!"
echo "--------------------------------------------"


