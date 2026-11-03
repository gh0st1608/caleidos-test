# module: alb-ingress

Tier **edge** del cluster:

- SG del ALB (80/443 desde `ingress_cidrs`) y la regla `ALB → nodes:backend_ports`. El Ingress referencia el SG por nombre (`alb.ingress.kubernetes.io/security-groups`) con `manage-backend-security-group-rules: "false"`, de modo que todo el flujo de red queda declarado en Terraform.
- **AWS Load Balancer Controller** (Helm, chart `3.6.0`) con IAM vía **EKS Pod Identity**. No requiere OIDC provider ni anotaciones en la ServiceAccount.
- `iam_policy.json` es la política oficial del proyecto en el tag `v3.6.0`. Al subir `chart_version`, se actualiza el archivo desde `https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/<tag>/docs/install/iam_policy.json`.

| Input | Default | Descripción |
|---|---|---|
| `cluster_name`, `region`, `vpc_id` | — | Contexto del cluster |
| `node_security_group_id` | — | SG destino del tráfico del ALB |
| `alb_security_group_name` | — | Nombre/tag del SG del ALB |
| `listener_ports` | `[80, 443]` | Puertos públicos |
| `ingress_cidrs` | `["0.0.0.0/0"]` | Clientes permitidos |
| `backend_ports` | `[8080]` | Puertos de los pods |
| `chart_version` | `3.6.0` | Versión del controlador |

**Outputs:** `alb_security_group_id`, `alb_security_group_name`, `controller_role_arn`.

Requiere el provider `helm` configurado por el stack consumidor.
