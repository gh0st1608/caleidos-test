variable "cluster_name" {
  description = "Nombre del cluster EKS."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,38}$", var.cluster_name))
    error_message = "cluster_name: minúsculas, números y guiones; 3-39 caracteres."
  }
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes (en soporte estándar de EKS)."
  type        = string
}

variable "vpc_id" {
  description = "VPC donde se despliega el cluster."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets privadas (una por AZ) para control plane ENIs y nodos."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Se requieren al menos 2 subnets en AZs distintas."
  }
}

variable "endpoint_public_access" {
  description = "Expone el endpoint público del API server (necesario para runners hospedados por GitHub)."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs permitidos en el endpoint público. Restringir en entornos productivos."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_principal_arns" {
  description = "Roles/usuarios IAM con acceso cluster-admin (además del creador del cluster)."
  type        = list(string)
  default     = []
}

variable "viewer_principal_arns" {
  description = "Roles IAM con acceso de solo lectura (ej. rol de plan del pipeline)."
  type        = list(string)
  default     = []
}

variable "node_group" {
  description = "Configuración del managed node group."
  type = object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 30)
  })

  validation {
    condition     = var.node_group.min_size <= var.node_group.desired_size && var.node_group.desired_size <= var.node_group.max_size
    error_message = "Se requiere min_size <= desired_size <= max_size."
  }

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_group.capacity_type)
    error_message = "capacity_type debe ser ON_DEMAND o SPOT."
  }
}

variable "addons" {
  description = "Add-ons gestionados de EKS."
  type        = list(string)
  default     = ["vpc-cni", "kube-proxy", "coredns", "eks-pod-identity-agent", "metrics-server"]
}

variable "addon_configurations" {
  description = "configuration_values por add-on (se serializa a JSON)."
  type        = any
  default = {
    # Habilita la aplicación de NetworkPolicies por el VPC CNI.
    vpc-cni = { enableNetworkPolicy = "true" }
  }
}

variable "cluster_log_types" {
  description = "Logs del control plane enviados a CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "Retención de logs del control plane."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
