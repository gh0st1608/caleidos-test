#!/usr/bin/env bash
# Utilidades comunes para los scripts de despliegue y demo.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-acme-txn-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"
NAMESPACE="${NAMESPACE:-acme-txn}"
APP="${APP:-txn-web}"
OVERLAY="${OVERLAY:-k8s/overlays/dev}"

log() { printf '\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 || die "falta la herramienta '$bin'"
  done
}

kubeconfig() {
  aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION" >/dev/null
}

# Espera hasta que el ALB del Ingress tenga hostname (lo crea el AWS Load Balancer Controller).
alb_hostname() {
  local host="" timeout="${1:-300}" waited=0
  while [[ -z "$host" && "$waited" -lt "$timeout" ]]; do
    host="$(kubectl -n "$NAMESPACE" get ingress "$APP" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
    [[ -z "$host" ]] && { sleep 5; waited=$((waited + 5)); }
  done
  [[ -n "$host" ]] || die "el Ingress no obtuvo hostname en ${timeout}s"
  echo "$host"
}
