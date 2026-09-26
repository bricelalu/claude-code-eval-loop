#!/usr/bin/env bash
# Run on the T490. Exits non-zero on the first failed check.
set -euo pipefail
fail() { echo "FAIL: $*"; exit 1; }

command -v k3s >/dev/null || fail "k3s not installed"
for _ in $(seq 60); do k3s kubectl get nodes -o name 2>/dev/null | grep -q . && break; sleep 2; done
k3s kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null || fail "node not Ready"
[ "$(k3s kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="DiskPressure")].status}')" = False ] \
  || fail "node has DiskPressure"
k3s kubectl -n kube-system get deploy traefik >/dev/null 2>&1 && fail "traefik should be disabled"
k3s kubectl -n kube-system get ds -o name | grep -q svclb && fail "servicelb should be disabled"
k3s kubectl -n kube-system wait --for=condition=Ready pod -l k8s-app=kube-dns --timeout=180s >/dev/null \
  || fail "coredns pod not Ready (pods may be blocked from the API server by ufw)"
echo "OK: k3s $(k3s --version | head -1 | awk '{print $3}') Ready, no DiskPressure, servicelb and traefik disabled"
