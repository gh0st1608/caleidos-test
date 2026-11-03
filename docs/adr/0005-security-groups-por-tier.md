# ADR-0005: Security Groups por tier con reglas referenciadas entre SGs

## Contexto
El reto pide security groups por tier. El tráfico tiene tres saltos bien definidos: Internet → ALB → pods, y nodos ↔ control plane.

## Decisión

| Tier | Ingress | Egress |
|---|---|---|
| **edge** (ALB) | 80/443 desde `ingress_cidrs` | `nodes:8080` |
| **nodes** (workers y pods) | 8080 desde edge · todo desde sí mismo · 443 y 1025-65535 desde control-plane | 0.0.0.0/0 (vía NAT) |
| **control-plane** | 443 desde nodes | 1025-65535 hacia nodes (kubelet, webhooks) |

- Las reglas apuntan a **otro SG como origen** (`referenced_security_group_id`), no a CIDRs. Si cambian las IPs, las reglas siguen siendo correctas.
- Se usan los recursos `aws_vpc_security_group_ingress_rule` / `egress_rule`, una regla por recurso, en vez de bloques inline. Cada regla tiene su propia descripción y se evitan conflictos entre módulos.
- El tier edge lo crea el módulo `alb-ingress`, que agrega su propia regla sobre el SG de nodos. Cada módulo es dueño de las reglas de su tier.

## Alternativas consideradas
- **Usar solo el SG primario que crea EKS**: funciona, pero no separa los tiers ni deja ver el flujo.
- **Security Groups for Pods** (SG por pod, con branch ENIs): da más granularidad, pero exige instancias Nitro, tiene límites de ENI y suma complejidad.

## Consecuencias
- Se complementa con **NetworkPolicy** (default-deny en el namespace). El VPC CNI la aplica con `enableNetworkPolicy`. Es defensa en profundidad: SG en la capa de red de AWS y NetworkPolicy en la de Kubernetes.
- El egreso de los nodos es amplio (0.0.0.0/0). Restringirlo requiere VPC Endpoints y un proxy de salida.
