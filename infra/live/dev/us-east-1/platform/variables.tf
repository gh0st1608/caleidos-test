variable "project" {
  description = "Nombre corto del producto."
  type        = string
}

variable "environment" {
  description = "Entorno (dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser dev, staging o prod."
  }
}

variable "region" {
  description = "Región AWS."
  type        = string
}

variable "owner" {
  description = "Equipo dueño (tag Owner)."
  type        = string
}

variable "cost_center" {
  description = "Centro de costos (tag CostCenter)."
  type        = string
}

variable "data_classification" {
  description = "Clasificación de datos (tag DataClassification)."
  type        = string
}

variable "repository" {
  description = "Repositorio fuente (tag Repository)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC."
  type        = string
}

variable "availability_zones" {
  description = "AZs de la región."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true = un solo NAT (ahorro); false = NAT por AZ (HA)."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes del cluster."
  type        = string
}

variable "eks_public_access_cidrs" {
  description = "CIDRs permitidos en el endpoint público del API server."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_admin_principal_arns" {
  description = "Principales IAM con cluster-admin, además del creador (no repetir al creador)."
  type        = list(string)
  default     = []
}

variable "eks_viewer_principal_arns" {
  description = "Principales IAM de solo lectura (ej. rol de plan del pipeline)."
  type        = list(string)
  default     = []
}

variable "node_group" {
  description = "Configuración del managed node group."
  type = object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 30)
  })
}

variable "app_container_port" {
  description = "Puerto del contenedor de la aplicación (target del ALB)."
  type        = number
  default     = 8080
}
