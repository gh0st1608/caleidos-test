# ADR-0001: Tres módulos por responsabilidad y un stack de composición

## Contexto
El reto pide VPC, EKS y balanceador, todo en Terraform. Hay que demostrar código reutilizable sin sobre-ingeniería.

## Decisión
- `modules/` contiene **mecanismos** sin valores de entorno:
  - `network`: VPC, subnets, NAT, rutas, Flow Logs.
  - `eks-cluster`: control plane, nodos, add-ons, SG de control-plane y nodes.
  - `alb-ingress`: tier edge y AWS Load Balancer Controller.
- `live/<entorno>/<región>/platform` contiene la **composición**: nombres, tamaños, AZs y tags. No tiene lógica propia.
- Cada módulo expone pocos outputs. Los módulos se conectan por IDs (`vpc_id`, `node_security_group_id`), nunca leyendo el state de otro.
- Las entradas se validan con `validation` (por ejemplo: 2 a 4 AZs, CIDR ≥ /18, `min ≤ desired ≤ max`).
- Los recursos repetidos usan `for_each` con claves estables (la AZ), no `count`.

## Alternativas consideradas
- **Un solo `main.tf` plano**: más rápido de escribir, pero no se puede reutilizar ni testear por partes.
- **Módulos comunitarios** (`terraform-aws-modules/vpc`, `/eks`): son maduros, pero ocultan las decisiones que el reto quiere evaluar y agregan cientos de variables.
- **Un stack por módulo** (red, cluster y app con states separados): reduce el radio de impacto, pero exige `remote_state` y coordinar el orden. Es excesivo para un entorno.

## Consecuencias
- Un solo `apply` levanta toda la plataforma. Un error en un módulo bloquea el `apply` completo (radio de impacto = entorno dev).
- Un entorno nuevo (por ejemplo `prod/us-east-1`) es solo otro directorio `live` con su `tfvars`.
- En una organización, `modules/` iría en un repositorio propio y se consumiría con `?ref=vX.Y.Z`.
