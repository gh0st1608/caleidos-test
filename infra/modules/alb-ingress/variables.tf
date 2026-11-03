variable "cluster_name" {
  description = "Nombre del cluster EKS."
  type        = string
}

variable "region" {
  description = "Región AWS del cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC del cluster."
  type        = string
}

variable "node_security_group_id" {
  description = "SG del tier de nodos/pods al que el ALB envía tráfico."
  type        = string
}

variable "alb_security_group_name" {
  description = "Nombre (y tag Name) del SG del ALB; el Ingress lo referencia por este valor."
  type        = string
}

variable "listener_ports" {
  description = "Puertos expuestos por el ALB."
  type        = list(number)
  default     = [80, 443]
}

variable "ingress_cidrs" {
  description = "CIDRs de clientes permitidos hacia el ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "backend_ports" {
  description = "Puertos de contenedor alcanzables desde el ALB (target-type ip)."
  type        = list(number)
  default     = [8080]
}

variable "chart_version" {
  description = "Versión del chart aws-load-balancer-controller (debe coincidir con iam_policy.json)."
  type        = string
  default     = "3.6.0"
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
