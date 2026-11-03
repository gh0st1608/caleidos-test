#!/usr/bin/env bash
# Despliega los manifests de la aplicación y verifica (rollout + smoke test vía ALB).
# Uso: scripts/deploy-app.sh
source "$(dirname "$0")/lib.sh"
require aws kubectl curl

kubeconfig
log "Aplicando $OVERLAY en el cluster $CLUSTER_NAME"
kubectl apply -k "$OVERLAY"

log "Esperando rollout de deployment/$APP"
kubectl -n "$NAMESPACE" rollout status "deployment/$APP" --timeout=300s

log "Esperando el ALB (la primera vez tarda ~2-3 min)"
HOST="$(alb_hostname 420)"

log "Smoke test: http://$HOST/healthz"
for i in $(seq 1 30); do
  if curl -fsS --max-time 5 "http://$HOST/healthz" >/dev/null 2>&1; then
    log "OK -> http://$HOST"
    exit 0
  fi
  sleep 10
done
die "el smoke test falló (los targets del ALB pueden seguir registrándose)"
