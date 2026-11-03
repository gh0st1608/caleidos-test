output "cluster_name" {
  description = "Nombre del cluster EKS."
  value       = module.eks.cluster_name
}

output "region" {
  description = "Región."
  value       = var.region
}

output "kubeconfig_command" {
  description = "Comando para configurar kubectl."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "vpc_id" {
  description = "ID de la VPC."
  value       = module.network.vpc_id
}

output "nat_public_ips" {
  description = "IPs de egreso."
  value       = module.network.nat_public_ips
}

output "alb_security_group_name" {
  description = "SG que el Ingress referencia en alb.ingress.kubernetes.io/security-groups."
  value       = module.alb_ingress.alb_security_group_name
}
