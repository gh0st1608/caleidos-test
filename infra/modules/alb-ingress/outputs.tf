output "alb_security_group_id" {
  description = "ID del SG del ALB."
  value       = aws_security_group.alb.id
}

output "alb_security_group_name" {
  description = "Nombre del SG del ALB (usado en la anotación del Ingress)."
  value       = aws_security_group.alb.name
}

output "controller_role_arn" {
  description = "Rol IAM del AWS Load Balancer Controller."
  value       = aws_iam_role.controller.arn
}
