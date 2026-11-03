#!/usr/bin/env bash
# Demo 1 - Balanceo de tráfico: N requests al ALB y conteo por Pod / Nodo / AZ.
# Uso: scripts/demo-balancing.sh [requests]
source "$(dirname "$0")/lib.sh"
require kubectl curl awk

REQUESTS="${1:-60}"
HOST="$(alb_hostname 60)"

log "Pods del Deployment (cada uno en su nodo/AZ):"
kubectl -n "$NAMESPACE" get pods -l "app.kubernetes.io/name=$APP" -o wide
echo

# Mapa nodo -> AZ para enriquecer la salida.
declare -A ZONE
while read -r node zone; do ZONE["$node"]="$zone"; done < <(
  kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.labels.topology\.kubernetes\.io/zone}{"\n"}{end}'
)

log "Enviando $REQUESTS requests a http://$HOST/whoami"
RESULTS="$(mktemp)"
for _ in $(seq 1 "$REQUESTS"); do
  # Conexión nueva por request; el ALB igual balancea por request dentro de una misma conexión.
  line="$(curl -fsS --max-time 5 "http://$HOST/whoami" || echo "pod=ERROR ip=- node=-")"
  node="$(sed -E 's/.*node=([^ ]+).*/\1/' <<<"$line")"
  echo "$line zone=${ZONE[$node]:--}" | tee -a "$RESULTS"
done

echo
log "Distribución de respuestas por Pod:"
awk '{ split($1,p,"="); split($4,z,"="); c[p[2]" ("z[2]")"]++ } END { for (k in c) printf "  %-50s %3d\n", k, c[k] }' "$RESULTS" | sort
rm -f "$RESULTS"
echo
log "Tip: abre http://$HOST en el navegador; la página se refresca cada 2s mostrando el Pod que responde."
