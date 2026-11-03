#!/usr/bin/env bash
# Demo 2 - Autoscaling (HPA): ejecuta stress-ng dentro del sidecar "stress" de los Pods
# actuales y muestra cómo el HPA aumenta las réplicas; al terminar, observa el scale-in.
#
# Uso: scripts/demo-hpa.sh [cpu|memory] [segundos]
source "$(dirname "$0")/lib.sh"
require kubectl

MODE="${1:-cpu}"
DURATION="${2:-240}"

case "$MODE" in
  cpu)    STRESS_ARGS=(--cpu 1 --cpu-load 100) ;;
  memory) STRESS_ARGS=(--vm 1 --vm-bytes 256M --vm-keep) ;;
  *)      die "modo inválido '$MODE' (cpu|memory)" ;;
esac

kubectl -n "$NAMESPACE" get hpa "$APP" >/dev/null || die "no existe el HPA $APP"

PODS=($(kubectl -n "$NAMESPACE" get pods -l "app.kubernetes.io/name=$APP" \
  --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}'))
[[ ${#PODS[@]} -gt 0 ]] || die "no hay Pods en ejecución"

log "Estado inicial:"
kubectl -n "$NAMESPACE" get hpa "$APP"
echo

log "Lanzando stress-ng (${MODE}, ${DURATION}s) en ${#PODS[@]} Pods: ${PODS[*]}"
for pod in "${PODS[@]}"; do
  kubectl -n "$NAMESPACE" exec "$pod" -c stress -- \
    stress-ng "${STRESS_ARGS[@]}" --timeout "${DURATION}s" --quiet >/dev/null 2>&1 &
done
trap 'log "Interrumpido: deteniendo stress-ng"; kill $(jobs -p) 2>/dev/null || true' INT TERM

# Monitoreo: utilización y réplicas cada 15s (el HPA evalúa cada ~15s; metrics-server ~15-60s de latencia).
END=$(( $(date +%s) + DURATION + 180 ))
printf '\n%-10s %-28s %-9s %-9s\n' "HORA" "TARGETS (cpu, memory)" "DESEADAS" "ACTUALES"
while [[ $(date +%s) -lt $END ]]; do
  targets="$(kubectl -n "$NAMESPACE" get hpa "$APP" --no-headers | awk '{print $3, $4}')"
  desired="$(kubectl -n "$NAMESPACE" get hpa "$APP" -o jsonpath='{.status.desiredReplicas}')"
  current="$(kubectl -n "$NAMESPACE" get hpa "$APP" -o jsonpath='{.status.currentReplicas}')"
  printf '%-10s %-28s %-9s %-9s\n' "$(date +%H:%M:%S)" "$targets" "$desired" "$current"
  sleep 15
done

wait || true
echo
log "Eventos del HPA:"
kubectl -n "$NAMESPACE" describe hpa "$APP" | sed -n '/Events:/,$p'
log "El scale-in completo ocurre tras la ventana de estabilización (120s). Observa con: kubectl -n $NAMESPACE get hpa $APP -w"
