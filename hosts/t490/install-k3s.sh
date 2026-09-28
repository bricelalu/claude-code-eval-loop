#!/usr/bin/env bash
# Run on the T490 as root. Idempotent.
set -euo pipefail
K3S_VERSION=v1.36.4+k3s1
# sha256 of install.sh at the K3S_VERSION git tag; the install aborts if it does not match.
INSTALLER_SHA256=46177d4c99440b4c0311b67233823a8e8a2fc09693f6c89af1a7161e152fbfad

install -D -m 0644 "$(dirname "$0")/k3s-config.yaml" /etc/rancher/k3s/config.yaml
# ufw denies by default; pods may reach only the API server (6443) and kubelet (10250),
# and only on the pod-facing bridge — never the LAN or tailnet interfaces.
ufw delete allow from 10.42.0.0/16 to any comment 'k3s pods' >/dev/null 2>&1 || true
ufw delete allow from 10.43.0.0/16 to any comment 'k3s services' >/dev/null 2>&1 || true
ufw allow in on cni0 from 10.42.0.0/16 to any port 6443,10250 proto tcp comment 'k3s pods'
curl -sfL "https://raw.githubusercontent.com/k3s-io/k3s/${K3S_VERSION}/install.sh" -o /tmp/k3s-install.sh
echo "${INSTALLER_SHA256}  /tmp/k3s-install.sh" | sha256sum -c - >/dev/null \
  || { rm -f /tmp/k3s-install.sh; echo "FAIL: k3s installer sha256 mismatch" >&2; exit 1; }
INSTALL_K3S_VERSION="$K3S_VERSION" sh /tmp/k3s-install.sh
rm -f /tmp/k3s-install.sh
