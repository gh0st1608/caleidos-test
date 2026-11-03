output "cluster_name" {
  description = "Nombre del cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint del API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "CA del cluster (base64)."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Primary SG gestionado por EKS."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "SG del tier de nodos/pods."
  value       = aws_security_group.nodes.id
}

output "node_role_arn" {
  description = "Rol IAM de los nodos."
  value       = aws_iam_role.nodes.arn
}

output "node_group_name" {
  description = "Nombre del managed node group."
  value       = aws_eks_node_group.default.node_group_name
}

# Permite a otros módulos (ej. controladores con Helm) esperar a que el cluster esté operativo.
output "addons_ready" {
  description = "IDs de add-ons; usar como dependencia explícita."
  value       = { for k, a in aws_eks_addon.this : k => a.id }
}
