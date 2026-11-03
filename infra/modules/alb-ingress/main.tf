locals {
  common_tags = merge(var.tags, { Module = "alb-ingress" })
  sa_name     = "aws-load-balancer-controller"
}

# ---------------------------------------------------------------------------
# Tier edge: SG del ALB. El Ingress lo referencia por nombre (tag Name) y el
# controlador NO gestiona reglas de backend: todo el flujo queda en Terraform.
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:Lo adjunta al ALB el AWS Load Balancer Controller (anotación security-groups del Ingress).
  name        = var.alb_security_group_name
  description = "Tier edge: ALB publico"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = var.alb_security_group_name, Tier = "edge" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_listeners" {
  #checkov:skip=CKV_AWS_260:ALB internet-facing; el puerto 80 solo redirige a HTTPS cuando hay certificado.
  for_each = { for pair in setproduct(var.listener_ports, var.ingress_cidrs) : "${pair[0]}-${pair[1]}" => pair }

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value[1]
  ip_protocol       = "tcp"
  from_port         = each.value[0]
  to_port           = each.value[0]
  description       = "Clientes -> ALB :${each.value[0]}"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_pods" {
  for_each = toset([for p in var.backend_ports : tostring(p)])

  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = var.node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = tonumber(each.key)
  to_port                      = tonumber(each.key)
  description                  = "ALB -> pods (target-type ip) :${each.key}"
}

resource "aws_vpc_security_group_ingress_rule" "pods_from_alb" {
  for_each = toset([for p in var.backend_ports : tostring(p)])

  security_group_id            = var.node_security_group_id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = tonumber(each.key)
  to_port                      = tonumber(each.key)
  description                  = "ALB -> pods :${each.key}"
}

# ---------------------------------------------------------------------------
# IAM vía EKS Pod Identity (sin OIDC provider ni anotaciones en la SA)
# Política oficial del proyecto, versionada junto al chart (iam_policy.json).
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "controller" {
  name        = "${var.cluster_name}-aws-load-balancer-controller"
  description = "AWS Load Balancer Controller ${var.chart_version}"
  policy      = file("${path.module}/iam_policy.json")
  tags        = local.common_tags
}

resource "aws_iam_role" "controller" {
  name = "${var.cluster_name}-aws-load-balancer-controller"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "controller" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller.arn
}

resource "aws_eks_pod_identity_association" "controller" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = local.sa_name
  role_arn        = aws_iam_role.controller.arn
  tags            = local.common_tags
}

resource "helm_release" "controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version

  # region/vpcId explícitos: los pods no acceden a IMDS (hop limit = 1).
  values = [yamlencode({
    clusterName  = var.cluster_name
    region       = var.region
    vpcId        = var.vpc_id
    replicaCount = 2
    serviceAccount = {
      create = true
      name   = local.sa_name
    }
    podDisruptionBudget = { maxUnavailable = 1 }
    resources = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { memory = "256Mi" }
    }
  })]

  wait    = true
  timeout = 600

  depends_on = [
    aws_eks_pod_identity_association.controller,
    aws_iam_role_policy_attachment.controller,
    aws_vpc_security_group_ingress_rule.pods_from_alb,
  ]
}
