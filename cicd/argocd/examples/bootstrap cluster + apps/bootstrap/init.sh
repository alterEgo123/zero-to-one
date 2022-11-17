#!/bin/bash

# Create repository and API Token variables
read -p "Enter the full repository URL (with .git at the end): " repository
read -p "Enter the Git API token with api scope permissions: " git_api_token
read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Set the working directory to always be argocd/²/
cd "$(dirname "${BASH_SOURCE[0]}")"

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd -n argocd argo/argo-cd -f values.yml

echo "ArgoCD password..."
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Create a secret for the infrastructure repository
echo "Configuring repository access..."
kubectl create secret generic example-infrastructure-repo --namespace=argocd --type=Opaque --from-literal=url=$repository --from-literal=password=$git_api_token
kubectl label secret -n argocd example-infrastructure-repo argocd.argoproj.io/secret-type=repository

# Create project
echo "Creating the main project..."
kubectl apply -f manifests/project.yml

# Create the app of apps
echo "Creating the app of apps..."
kubectl apply -f manifests/application.yml
