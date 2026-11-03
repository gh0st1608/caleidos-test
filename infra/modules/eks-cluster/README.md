# module: eks-cluster

Cluster EKS con:

- Control plane con endpoint privado + público (acotable por CIDR), logs a CloudWatch y cifrado KMS de Secrets.
- Autenticación por **EKS Access Entries** (`authentication_mode = "API"`), sin el ConfigMap `aws-auth`.
- **Managed Node Group** multi-AZ con Launch Template endurecido: IMDSv2 con hop limit 1, EBS gp3 cifrado y acceso por SSM en lugar de SSH.
- Security Groups por tier: `control-plane` y `nodes`. El tier `edge` lo agrega el módulo `alb-ingress`.
- Add-ons gestionados: `vpc-cni` (con NetworkPolicy habilitado), `kube-proxy`, `coredns`, `eks-pod-identity-agent` y `metrics-server`, este último requerido por el HPA.

| Input | Descripción |
|---|---|
| `cluster_name`, `kubernetes_version` | Identidad y versión |
| `vpc_id`, `subnet_ids` | Red (subnets privadas, ≥ 2 AZs) |
| `endpoint_public_access`, `public_access_cidrs` | Exposición del API server |
| `admin_principal_arns`, `viewer_principal_arns` | Access entries (admin / solo lectura) |
| `node_group` | Tipos, capacidad (ON_DEMAND/SPOT), min/desired/max, disco |
| `addons`, `addon_configurations` | Add-ons y su configuración |
| `cluster_log_types`, `log_retention_days` | Logging |

**Outputs:** `cluster_name`, `cluster_endpoint`, `cluster_certificate_authority_data`, `cluster_security_group_id`, `node_security_group_id`, `node_role_arn`, `node_group_name` y `addons_ready`.
