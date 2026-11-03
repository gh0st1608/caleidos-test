output "vpc_id" {
  description = "ID de la VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs de subnets públicas (orden de availability_zones)."
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "IDs de subnets privadas (orden de availability_zones)."
  value       = [for az in var.availability_zones : aws_subnet.private[az].id]
}

output "nat_public_ips" {
  description = "IPs públicas de egreso (útil para allowlists de terceros)."
  value       = [for eip in aws_eip.nat : eip.public_ip]
}
