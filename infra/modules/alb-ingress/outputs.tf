output "alb_security_group_name" {
  description = "Nombre del SG del ALB (usado en la anotación del Ingress)."
  value       = aws_security_group.alb.name
}
