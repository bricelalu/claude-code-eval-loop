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
k3s kubectl -n kube-system wait --for=condition=Ready pod -l k8s-app=metrics-server --timeout=180s >/dev/null \
  || fail "metrics-server pod not Ready (kubelet metrics port 10250 may be blocked by ufw)"

# ADR 0002: nothing binds to the LAN. kube-proxy must program NodePort rules only for
# the tailnet IP (nodeport-addresses=100.95.91.56/32), so a NodePort answers on the
# tailnet IP and nowhere else.
LAN_IP=192.168.1.32
TAILNET_IP=100.95.91.56
cleanup() { k3s kubectl delete deployment,service np-check --wait=false >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup
k3s kubectl create deployment np-check --image=traefik/whoami --replicas=1 >/dev/null
k3s kubectl expose deployment np-check --type=NodePort --port=80 --target-port=80 --name=np-check >/dev/null
NODEPORT=$(k3s kubectl get service np-check -o jsonpath='{.spec.ports[0].nodePort}')
k3s kubectl wait --for=condition=Ready pod -l app=np-check --timeout=180s >/dev/null \
  || fail "np-check pod not Ready (image pull may have failed)"
# kube-proxy programs the NodePort rules a few seconds after the endpoint appears;
# wait for the tailnet IP to answer before drawing any conclusion about the LAN IP.
for _ in $(seq 30); do curl -sf --max-time 2 "http://${TAILNET_IP}:${NODEPORT}" >/dev/null 2>&1 && break; sleep 1; done
curl -sf --max-time 3 "http://${TAILNET_IP}:${NODEPORT}" >/dev/null \
  || fail "NodePort ${NODEPORT} does not answer on the tailnet IP ${TAILNET_IP}"
if curl -sf --max-time 3 "http://${LAN_IP}:${NODEPORT}" >/dev/null; then
  fail "NodePort ${NODEPORT} answers on the LAN IP ${LAN_IP}; kube-proxy nodeport-addresses is not restricted to the tailnet IP"
fi
echo "OK: k3s $(k3s --version | head -1 | awk '{print $3}') Ready, no DiskPressure, servicelb and traefik disabled, NodePort tailnet-only"
