variable "project" {
  description = "Prefijo del proyecto."
  type        = string
  default     = "acme-txn"
}

variable "owner" {
  description = "Equipo dueño."
  type        = string
  default     = "team-cloud"
}

variable "region" {
  description = "Región del bucket de state."
  type        = string
  default     = "us-east-1"
}

variable "github_repository" {
  description = "Repositorio autorizado a asumir los roles, formato org/repo."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Formato esperado: org/repo."
  }
}

variable "github_owner_id" {
  description = "ID numérico del owner en GitHub. GitHub firma el sub del token OIDC como repo:owner@ID/repo@ID:..."
  type        = string
  default     = ""
}

variable "github_repository_id" {
  description = "ID numérico del repositorio en GitHub (ver github_owner_id). Vacío = solo formato org/repo."
  type        = string
  default     = ""
}

variable "github_environments" {
  description = "GitHub Environments protegidos que pueden asumir el rol de apply."
  type        = list(string)
  default     = ["dev"]
}

variable "create_github_oidc_provider" {
  description = "false si la cuenta ya tiene el OIDC provider de GitHub (es único por cuenta)."
  type        = bool
  default     = true
}
