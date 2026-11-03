# Architecture Decision Records

Decisiones de arquitectura de los módulos Terraform `network`, `eks-cluster` y `alb-ingress`, y de su composición en `infra/live/dev/us-east-1/platform`.

Formato: contexto → decisión → alternativas → consecuencias. Estado de todas: **Aceptada** (2026-11-01).

| ADR | Decisión |
|---|---|
| [0001](0001-estructura-modulos-y-stacks.md) | Tres módulos por responsabilidad, compuestos por un stack por entorno/región |
| [0002](0002-state-remoto-s3-lockfile.md) | State remoto en S3 con lock nativo (`use_lockfile`) y bootstrap separado |
| [0003](0003-topologia-de-red.md) | VPC /16 en 3 AZs: públicas /24 solo para borde, privadas /20 para nodos y pods |
| [0004](0004-nat-gateway-por-az.md) | Un NAT Gateway por AZ, con opción de uno solo para ahorrar |
| [0005](0005-security-groups-por-tier.md) | Security Groups por tier con reglas referenciadas entre SGs |
| [0006](0006-control-plane-eks.md) | EKS con Access Entries, cifrado KMS, logs completos y endpoint acotable |
| [0007](0007-managed-node-group.md) | Managed Node Group con Launch Template endurecido |
| [0008](0008-addons-gestionados.md) | Add-ons gestionados por EKS, incluido `metrics-server` |
| [0009](0009-exposicion-alb-ingress.md) | ALB vía AWS Load Balancer Controller con `target-type: ip` |
| [0010](0010-pod-identity.md) | EKS Pod Identity en lugar de IRSA |
| [0011](0011-sg-alb-en-terraform.md) | SG del ALB y reglas de backend declarados en Terraform, no por el controlador |
| [0012](0012-plataforma-terraform-app-kustomize.md) | Controlador de plataforma con Helm en Terraform; aplicación con Kustomize |
| [0013](0013-calidad-y-excepciones.md) | Validación automática y excepciones de seguridad documentadas en el código |
