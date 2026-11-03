# Tiers:
#   control-plane  -> SG adicional en las ENIs del API server
#   nodes          -> SG de los workers (y de los pods, que comparten ENI con VPC CNI)
#   edge (ALB)     -> definido en el módulo alb-ingress, que agrega su regla hacia "nodes"

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-control-plane"
  description = "Tier control-plane: API server de EKS"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = "${var.cluster_name}-control-plane", Tier = "control-plane" })
}

resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "Tier nodes: workers EKS y pods"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = "${var.cluster_name}-nodes", Tier = "nodes" })
}

# --- control-plane ----------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "cluster_from_nodes_https" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Nodes to API server"
}

resource "aws_vpc_security_group_egress_rule" "cluster_to_nodes" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 1025
  to_port                      = 65535
  description                  = "API server to kubelet y webhooks"
}

# --- nodes ------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "nodes_from_self" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
  description                  = "Node to node y pod to pod (CoreDNS, servicios internos)"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster" {
  #checkov:skip=CKV_AWS_25:Falso positivo: el origen es el SG del control plane, no 0.0.0.0/0.
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 1025
  to_port                      = 65535
  description                  = "API server to kubelet (10250) y webhooks (ej. LBC 9443)"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster_https" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "API server to webhooks en 443"
}

# Egreso a Internet vía NAT: pull de imágenes, APIs de AWS y registro en el cluster.
resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  #checkov:skip=CKV_AWS_382:Los nodos requieren egreso (NAT) para ECR/registries y APIs de AWS; sin endpoints privados en este alcance.
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Egreso via NAT Gateway"
}
