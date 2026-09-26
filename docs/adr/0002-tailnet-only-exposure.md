# Tailnet-only exposure through the Tailscale operator

All cluster services (Grafana, Argo CD, Jaeger and the OTLP endpoint) are reached only over the tailnet through the Tailscale Kubernetes operator. k3s's built-in servicelb is disabled. The default k3s ingress path binds Traefik to every host interface, and the host sits on a shared home LAN. Tailnet ACLs, kept in this repo, give identity-based access plus HTTPS. The price is one OAuth secret, which lives in git encrypted with Sealed Secrets.
