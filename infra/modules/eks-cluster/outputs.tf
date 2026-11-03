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

output "node_security_group_id" {
  description = "SG del tier de nodos/pods."
  value       = aws_security_group.nodes.id
}
