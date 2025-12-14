#!/bin/bash -xe

echo "--- START: Dependency Installation via dedicated script ---"

# The Control Plane node is now ready, but we wait a little longer 
# for the cluster to fully settle, especially Calico/CNI.
echo "Waiting 60 seconds for cluster components to settle..."
sleep 60

#############################################
# 1. Install Helm
#############################################
echo "--- Installing Helm ---"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

#############################################
# 2. Add Helm Repositories
#############################################
echo "--- Adding Helm Repositories ---"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

#############################################
# 3. Install Cluster Dependencies
#############################################
echo "--- Installing Dependencies (PostgreSQL and Ingress) ---"

# Install PostgreSQL (Required for Catalog and Orders)
/usr/local/bin/helm install retail-db-postgres bitnami/postgresql \
  --namespace default \
  --set auth.postgresPassword=mypassword \
  --version 14.1.2

# Install NGINX Ingress Controller (Required for external access)
/usr/local/bin/helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace ingress-nginx

echo "--- Dependency Installation COMPLETE ---"
