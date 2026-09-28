#!/usr/bin/env bash
# Run on the T490 as root. Idempotent. Installs Argo CD core (no Dex, no HA
# redis) and applies the root Application, which syncs clusters/t490/ from git.
set -euo pipefail
ARGOCD_VERSION=v3.5.3
# sha256 of core-install.yaml at the ARGOCD_VERSION git tag; the install aborts if it does not match.
ARGOCD_SHA256=1a87025d8eb2eae621653fd312fb9ca51df1b4b3b6992a030e3a9ef38e45c448

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
curl -sfL "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/core-install.yaml" -o /tmp/argocd-core-install.yaml
echo "${ARGOCD_SHA256}  /tmp/argocd-core-install.yaml" | sha256sum -c - >/dev/null \
  || { rm -f /tmp/argocd-core-install.yaml; echo "FAIL: Argo CD manifest sha256 mismatch" >&2; exit 1; }
kubectl apply -n argocd -f /tmp/argocd-core-install.yaml
rm -f /tmp/argocd-core-install.yaml

# Wait for the Argo CD server to be ready before applying the root app.
kubectl -n argocd wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server --timeout=300s

kubectl apply -f "$(dirname "$0")/root-app.yaml"
echo "OK: Argo CD ${ARGOCD_VERSION} installed, root Application applied"
