# ADR-0011: SG del ALB y reglas de backend en Terraform

## Contexto
Por defecto, el Load Balancer Controller crea el SG del ALB y modifica las reglas del SG de los nodos. Así, parte de la red queda fuera de Terraform: no aparece en el plan ni la revisa Checkov, y genera drift.

## Decisión
- Terraform crea el SG **edge** (`acme-txn-dev-alb`) y las reglas `ALB → nodes:8080`.
- El Ingress lo referencia **por nombre** (`alb.ingress.kubernetes.io/security-groups: acme-txn-dev-alb`), con `manage-backend-security-group-rules: "false"`.
- Se referencia por nombre, no por ID, para que los manifests no dependan de outputs dinámicos de Terraform.

## Alternativas consideradas
- **Dejar que el controlador gestione los SGs**: requiere menos configuración, pero las reglas no se ven en el código ni pasan por revisión.
- **Pasar el ID del SG a los manifests** (por ejemplo, generando un patch de Kustomize desde un output): agrega un acoplamiento Terraform → Kubernetes en el pipeline.

## Consecuencias
- Todo el flujo de red queda declarado, versionado y escaneado en un solo lugar.
- El nombre del SG es un contrato entre Terraform y el overlay de Kubernetes. Si cambia uno, hay que cambiar el otro.
