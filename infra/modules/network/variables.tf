variable "name" {
  description = "Prefijo lógico de los recursos de red (ej. acme-txn-dev)."
  type        = string
}

variable "cidr_block" {
  description = "CIDR de la VPC. Se recomienda /16 para dejar espacio a IPs de pods (VPC CNI)."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && tonumber(split("/", var.cidr_block)[1]) <= 18
    error_message = "cidr_block debe ser un CIDR IPv4 válido de tamaño /18 o mayor."
  }
}

variable "availability_zones" {
  description = "AZs a utilizar. Mínimo 2 para alta disponibilidad."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 4
    error_message = "Se requieren entre 2 y 4 AZs para alta disponibilidad."
  }
}

variable "single_nat_gateway" {
  description = "Usa un único NAT (ahorro de costos, sin HA de egreso). false = un NAT por AZ."
  type        = bool
  default     = false
}

variable "public_subnet_tags" {
  description = "Tags adicionales para subnets públicas (ej. descubrimiento de ALB por EKS)."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Tags adicionales para subnets privadas."
  type        = map(string)
  default     = {}
}

variable "enable_flow_logs" {
  description = "Habilita VPC Flow Logs hacia CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retención de los Flow Logs en días."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
