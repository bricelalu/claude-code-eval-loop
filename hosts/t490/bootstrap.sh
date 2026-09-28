#!/usr/bin/env bash
# Run on the T490 as root. Idempotent. Installs Argo CD core (no Dex, no HA
# redis) and applies the root Application, which syncs clusters/t490/ from git.
set -euo pipefail
ARGOCD_VERSION=v3.5.3
# sha256 of install.yaml at the ARGOCD_VERSION git tag; the install aborts if it does not match.
ARGOCD_SHA256=7efe2d6bbc03f63623640f1e4198f16c84009d510fb810ef71e56df1b7614ba9

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
curl -sfL "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" -o /tmp/argocd-install.yaml
echo "${ARGOCD_SHA256}  /tmp/argocd-install.yaml" | sha256sum -c - >/dev/null \
  || { rm -f /tmp/argocd-install.yaml; echo "FAIL: Argo CD manifest sha256 mismatch" >&2; exit 1; }
# Strip the Dex resources: we run core Argo CD (no Dex, no HA redis).
python3 -c "
import re
docs = re.split(r'(?m)^---[ \t]*\$', open('/tmp/argocd-install.yaml').read())
kept = [d for d in docs if not re.search(r'(?m)^  name: .*dex', d)]
open('/tmp/argocd-nodex.yaml', 'w').write('\n---\n'.join(kept))
"
kubectl apply --server-side --force-conflicts -n argocd -f /tmp/argocd-nodex.yaml
rm -f /tmp/argocd-install.yaml /tmp/argocd-nodex.yaml

# Wait for the Argo CD server to be ready before applying the root app.
kubectl -n argocd wait --for=condition=Available deployment/argocd-server --timeout=300s

kubectl apply -f "$(dirname "$0")/root-app.yaml"
echo "OK: Argo CD ${ARGOCD_VERSION} installed, root Application applied"
