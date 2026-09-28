#!/usr/bin/env bash
# Run on the T490. Exits non-zero on the first failed check.
# Asserts every Argo Application is Synced and Healthy, and that no Service is
# NodePort or LoadBalancer (ADR 0002: tailnet-only exposure).
set -euo pipefail
fail() { echo "FAIL: $*"; exit 1; }

command -v kubectl >/dev/null || fail "kubectl not found"
command -v jq >/dev/null || fail "jq not found"
kubectl get ns argocd >/dev/null 2>&1 || fail "argocd namespace not found (run bootstrap.sh first)"

# Wait for every Argo Application to become Synced and Healthy.
for _ in $(seq 90); do
  not_ready=$(kubectl get applications -n argocd -o json 2>/dev/null \
    | jq '[.items[] | select(.status.sync.status != "Synced" or .status.health.status != "Healthy")] | length')
  [ "$not_ready" = 0 ] && break
  sleep 2
done

# There must be at least the root Application.
[ "$(kubectl get applications -n argocd -o json 2>/dev/null | jq '.items | length')" -ge 1 ] \
  || fail "no Argo Applications found (run bootstrap.sh first)"

# Assert every Argo Application is Synced and Healthy.
while IFS= read -r line; do
  name=${line%% *}
  sync=$(echo "$line" | awk '{print $2}')
  health=$(echo "$line" | awk '{print $3}')
  [ "$sync" = Synced ] || fail "Application $name is $sync (not Synced)"
  [ "$health" = Healthy ] || fail "Application $name is $health (not Healthy)"
done < <(kubectl get applications -n argocd -o json 2>/dev/null \
  | jq -r '.items[] | "\(.metadata.name) \(.status.sync.status) \(.status.health.status)"')

# Assert no Service is NodePort or LoadBalancer (ADR 0002: tailnet-only).
bad_svc=$(kubectl get svc -A -o json 2>/dev/null \
  | jq -r '.items[] | select(.spec.type == "NodePort" or .spec.type == "LoadBalancer") | "\(.metadata.namespace)/\(.metadata.name) \(.spec.type)"')
[ -z "$bad_svc" ] || { echo "$bad_svc"; fail "found NodePort/LoadBalancer Services (ADR 0002: tailnet-only)"; }

count=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "OK: $count Argo Applications Synced+Healthy, no NodePort/LoadBalancer Services"
