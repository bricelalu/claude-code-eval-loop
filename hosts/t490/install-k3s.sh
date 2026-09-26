#!/usr/bin/env bash
# Run on the T490 as root. Idempotent.
set -euo pipefail
K3S_VERSION=v1.36.4+k3s1

install -D -m 0644 "$(dirname "$0")/k3s-config.yaml" /etc/rancher/k3s/config.yaml
# ufw denies by default; pods and services must reach the host (the API server, DNS).
ufw allow from 10.42.0.0/16 to any comment 'k3s pods'
ufw allow from 10.43.0.0/16 to any comment 'k3s services'
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -
