#!/usr/bin/env bash
# Rebuilds everything inside a fresh EKS cluster. Run after `terraform apply`.
set -euo pipefail
cd "$(dirname "$0")/.."

aws eks update-kubeconfig --region ap-south-1 --name ecommerce-eks
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes

kubectl apply -f platform/storageclass-gp3.yaml
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

PW=$(openssl rand -hex 12)
kubectl -n dev create secret generic db-credentials \
  --from-literal=POSTGRES_USER=shop \
  --from-literal=POSTGRES_PASSWORD="$PW" \
  --from-literal=POSTGRES_DB=shop \
  --from-literal=DATABASE_URL="postgresql+psycopg2://shop:${PW}@shop-postgres:5432/shop" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl apply -f argocd/shop-dev.yaml

echo "Done. Check: kubectl -n argocd get application shop-dev"
