# module: network

VPC multi-AZ con subnets públicas (/24, solo ALB y NAT) y privadas (/20, nodos y pods), un NAT Gateway por AZ (o uno solo con `single_nat_gateway`), tablas de ruteo privadas por AZ, SG por defecto sin reglas y VPC Flow Logs.

| Input | Tipo | Default | Descripción |
|---|---|---|---|
| `name` | string | — | Prefijo de recursos |
| `cidr_block` | string | — | CIDR de la VPC (≥ /18) |
| `availability_zones` | list(string) | — | 2 a 4 AZs |
| `single_nat_gateway` | bool | `false` | Un solo NAT (sin HA de egreso) |
| `public_subnet_tags` / `private_subnet_tags` | map(string) | `{}` | p. ej. tags de descubrimiento para ELB |
| `enable_flow_logs` | bool | `true` | Flow Logs a CloudWatch |
| `flow_logs_retention_days` | number | `30` | Retención |

**Outputs:** `vpc_id`, `vpc_cidr_block`, `public_subnet_ids`, `private_subnet_ids`, `nat_public_ips`.

```hcl
module "network" {
  source             = "../../../../modules/network"
  name               = "acme-txn-dev"
  cidr_block         = "10.40.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

Tests: `terraform test` (mock provider, sin credenciales).
