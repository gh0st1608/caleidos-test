data "aws_partition" "current" {}

locals {
  common_tags = merge(var.tags, { Module = "eks-cluster" })
  partition   = data.aws_partition.current.partition
}

# ---------------------------------------------------------------------------
# Cifrado de Secrets de Kubernetes (envelope encryption con KMS)
# ---------------------------------------------------------------------------
resource "aws_kms_key" "eks" {
  #checkov:skip=CKV2_AWS_64:Se usa la key policy por defecto (root de la cuenta + IAM); EKS accede vía el rol del cluster.
  description             = "EKS secrets encryption - ${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = local.common_tags
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks/${var.cluster_name}"
  target_key_id = aws_kms_key.eks.key_id
}

# Se crea antes que el cluster para controlar la retención (EKS la crearía sin expiración).
resource "aws_cloudwatch_log_group" "cluster" {
  #checkov:skip=CKV_AWS_158:Cifrado en reposo gestionado por CloudWatch; CMK opcional según clasificación de datos.
  #checkov:skip=CKV_AWS_338:Retención parametrizada por entorno (log_retention_days); prod debe usar >= 365.
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# ---------------------------------------------------------------------------
# Control plane
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  #checkov:skip=CKV_AWS_39:Endpoint público requerido por runners hospedados de GitHub; acotado con public_access_cidrs.
  #checkov:skip=CKV_AWS_38:public_access_cidrs es configurable por entorno; restringir en prod.
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  enabled_cluster_log_types = var.cluster_log_types

  # Evita el costo de soporte extendido de forma silenciosa: obliga a planificar upgrades.
  upgrade_policy {
    support_type = "STANDARD"
  }

  tags = merge(local.common_tags, { Name = var.cluster_name })

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.cluster,
  ]
}

# ---------------------------------------------------------------------------
# Acceso al cluster (EKS Access Entries, sin aws-auth ConfigMap)
# ---------------------------------------------------------------------------
locals {
  access_entries = merge(
    { for arn in var.admin_principal_arns : arn => "AmazonEKSClusterAdminPolicy" },
    { for arn in var.viewer_principal_arns : arn => "AmazonEKSAdminViewPolicy" },
  )
}

resource "aws_eks_access_entry" "this" {
  for_each = local.access_entries

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.key
  tags          = local.common_tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each = local.access_entries

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.this[each.key].principal_arn
  policy_arn    = "arn:${local.partition}:eks::aws:cluster-access-policy/${each.value}"

  access_scope {
    type = "cluster"
  }
}

# ---------------------------------------------------------------------------
# Managed Node Group (multi-AZ) con Launch Template endurecido
# ---------------------------------------------------------------------------
resource "aws_launch_template" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  description = "Nodos EKS ${var.cluster_name}: IMDSv2, EBS cifrado, SGs por tier."

  # Primary SG del cluster (comunicación con control plane) + SG del tier de nodos.
  vpc_security_group_ids = [
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
    aws_security_group.nodes.id,
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1 # Los pods no alcanzan IMDS: deben usar Pod Identity.
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_group.disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${var.cluster_name}-node" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.common_tags
  }

  tags = local.common_tags
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-default"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.subnet_ids

  ami_type       = var.node_group.ami_type
  capacity_type  = var.node_group.capacity_type
  instance_types = var.node_group.instance_types

  scaling_config {
    min_size     = var.node_group.min_size
    max_size     = var.node_group.max_size
    desired_size = var.node_group.desired_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  labels = {
    "workload-tier" = "app"
  }

  tags = local.common_tags

  lifecycle {
    # Un autoscaler de nodos (Cluster Autoscaler/Karpenter) puede ajustar desired_size.
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_iam_role_policy_attachment.nodes]
}

# ---------------------------------------------------------------------------
# Add-ons gestionados por EKS (versión por defecto compatible con kubernetes_version)
# ---------------------------------------------------------------------------
data "aws_eks_addon_version" "this" {
  for_each = toset(var.addons)

  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = false
}

resource "aws_eks_addon" "this" {
  for_each = toset(var.addons)

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = data.aws_eks_addon_version.this[each.key].version
  configuration_values        = try(jsonencode(var.addon_configurations[each.key]), null)
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = local.common_tags

  # coredns y metrics-server necesitan nodos para quedar ACTIVE.
  depends_on = [aws_eks_node_group.default]
}
