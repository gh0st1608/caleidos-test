# ADR-0007: Managed Node Group con Launch Template endurecido

## Contexto
El reto pide node groups. Hay que elegir entre nodos gestionados por AWS, autogestionados o Fargate, y definir su seguridad base.

## Decisión
- **Un Managed Node Group** en las 3 subnets privadas: **3 × t3.medium** (uno por AZ), con `min 3 / max 6`.
- AMI **Amazon Linux 2023** (`AL2023_x86_64_STANDARD`), parcheada por AWS.
- El **Launch Template** define:
  - **IMDSv2 obligatorio con `hop_limit = 1`**: los pods no pueden robar las credenciales del nodo y deben usar Pod Identity.
  - Disco **gp3 cifrado**.
  - SGs: primario del cluster + tier nodes.
  - Acceso por **SSM**, sin SSH ni key pairs.
- `update_config.max_unavailable_percentage = 33`: los upgrades rotan un nodo (una AZ) a la vez.
- `ignore_changes = [desired_size]`, para que un autoscaler de nodos pueda ajustar sin que Terraform lo revierta.

## Alternativas consideradas
- **Nodos autogestionados (ASG)**: dan más control, pero el drain y el upgrade quedan a cargo propio.
- **Fargate**: no hay nodos que operar, pero no permite DaemonSets, cobra por pod y no tiene sentido para demostrar node groups.
- **Karpenter**: es el estándar actual para escalar nodos, pero agrega un controlador, IAM y NodePools. Queda como siguiente paso.
- **Spot**: abarata, pero puede interrumpir la demo. `capacity_type` es variable.

## Consecuencias
- No hay escalado automático de **nodos**: el HPA escala pods dentro de la capacidad fija. El cálculo:
  - 12 pods × 150m de request ≈ 1.8 vCPU.
  - 3 nodos ≈ 5.7 vCPU asignables.
  - Cada t3.medium admite hasta 17 pods con VPC CNI.

  La capacidad alcanza para la demo con margen.
- Para producción se sumaría Cluster Autoscaler o Karpenter. El `ignore_changes` ya lo deja preparado.
