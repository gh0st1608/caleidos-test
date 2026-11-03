# Stack de composición: decisiones del producto (nombres, tamaños, AZs) + módulos reutilizables.
# En una organización, los `source` apuntarían a un repo de módulos con tag inmutable, p. ej.:
#   source = "git::https://github.com/org/terraform-platform.git//modules/network?ref=v1.2.0"

locals {
  name = "${var.project}-${var.environment}"
}

module "network" {
  source = "../../../../modules/network"

  name               = local.name
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway

  # Descubrimiento de subnets por el AWS Load Balancer Controller.
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}

module "eks" {
  source = "../../../../modules/eks-cluster"

  cluster_name       = local.name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids

  public_access_cidrs   = var.eks_public_access_cidrs
  admin_principal_arns  = var.eks_admin_principal_arns
  viewer_principal_arns = var.eks_viewer_principal_arns

  node_group = var.node_group
}

module "alb_ingress" {
  source = "../../../../modules/alb-ingress"

  cluster_name            = module.eks.cluster_name
  region                  = var.region
  vpc_id                  = module.network.vpc_id
  node_security_group_id  = module.eks.node_security_group_id
  alb_security_group_name = "${local.name}-alb"
  backend_ports           = [var.app_container_port]

  # El controlador necesita nodos y add-ons (pod identity agent) operativos.
  depends_on = [module.eks]
}
