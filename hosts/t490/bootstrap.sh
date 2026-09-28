#!/usr/bin/env bash
# Run on the T490 as root. Idempotent. Installs Argo CD core (no Dex, no HA
# redis) and applies the root Application, which syncs clusters/t490/ from git.
set -euo pipefail
ARGOCD_VERSION=v3.5.3

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/core-install.yaml"

# Wait for the Argo CD server to be ready before applying the root app.
kubectl -n argocd wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server --timeout=300s

kubectl apply -f "$(dirname "$0")/root-app.yaml"
echo "OK: Argo CD ${ARGOCD_VERSION} installed, root Application applied"
