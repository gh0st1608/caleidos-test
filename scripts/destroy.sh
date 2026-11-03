#!/usr/bin/env bash
# Destrucción ordenada: primero el Ingress (para que el controlador elimine el ALB y sus
# ENIs/target groups), luego la infraestructura. Si se invierte el orden, el ALB queda
# huérfano y bloquea la eliminación de la VPC.
# Uso: scripts/destroy.sh [-auto-approve]   (requiere backend inicializado en el stack)
source "$(dirname "$0")/lib.sh"
require aws kubectl terraform

STACK_DIR="${STACK_DIR:-infra/live/dev/us-east-1/platform}"

if kubeconfig 2>/dev/null; then
  log "Eliminando recursos de la aplicación"
  kubectl delete -k "$OVERLAY" --ignore-not-found --wait=true || true

  log "Esperando a que el controlador elimine el ALB"
  for _ in $(seq 1 36); do
    remaining="$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
      --query "LoadBalancers[?starts_with(LoadBalancerName, 'k8s-acmetxn')].LoadBalancerName" --output text)"
    [[ -z "$remaining" || "$remaining" == "None" ]] && break
    sleep 5
  done
else
  log "El cluster no existe o no es accesible; se omite la limpieza de Kubernetes"
fi

log "terraform destroy en $STACK_DIR"
terraform -chdir="$STACK_DIR" destroy -input=false "$@"
