# Fundaciones (se ejecuta UNA vez con credenciales de administrador, state local):
#   - Bucket S3 para remote state (versionado, cifrado, bloqueo nativo con lockfile)
#   - Federación OIDC GitHub Actions -> AWS (sin access keys permanentes)
#   - Rol "plan" (solo lectura) y rol "apply" (restringido al environment protegido)

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Application = var.project
      Owner       = var.owner
      ManagedBy   = "Terraform"
      Repository  = var.github_repository
      Stack       = "bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  state_bucket = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
  oidc_host    = "token.actions.githubusercontent.com"
  oidc_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : (
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_host}"
  )

  # Prefijos de sub aceptados: org/repo y, si se conocen los IDs, org@ID/repo@ID
  # (formato inmutable: un repo renombrado o recreado con el mismo nombre no hereda la confianza).
  github_owner = split("/", var.github_repository)[0]
  github_repo  = split("/", var.github_repository)[1]
  github_subjects = compact([
    "repo:${var.github_repository}",
    var.github_owner_id != "" && var.github_repository_id != "" ? "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repo}@${var.github_repository_id}" : "",
  ])
}

# ---------------------------------------------------------------------------
# Remote state
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_144:Replicación cross-region fuera de alcance para el reto.
  #checkov:skip=CKV_AWS_18:Access logging del bucket de state fuera de alcance; CloudTrail registra el acceso.
  #checkov:skip=CKV2_AWS_62:No se requieren notificaciones de eventos.
  bucket = local.state_bucket

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "state" {
  #checkov:skip=CKV2_AWS_64:Key policy por defecto; el acceso se concede vía políticas IAM de los roles del pipeline.
  description         = "Cifrado del remote state de Terraform"
  enable_key_rotation = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
}

locals {
  state_access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.state.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.state.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.state.arn
      },
    ]
  })
}

# Plan: PRs y push a main. Solo lectura + escritura del lockfile de state.
resource "aws_iam_role" "plan" {
  name = "${var.project}-gha-plan"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "${local.oidc_host}:aud" = "sts.amazonaws.com" }
        StringLike = {
          "${local.oidc_host}:sub" = flatten([
            for subject in local.github_subjects : ["${subject}:pull_request", "${subject}:ref:refs/heads/main"]
          ])
        }
      }
    }]
  })
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state"
  role   = aws_iam_role.plan.id
  policy = local.state_access_policy
}

# Apply: SOLO desde jobs que corren en el GitHub Environment protegido (aprobación manual).
# Trade-off documentado: AdministratorAccess por simplicidad del reto; en producción
# reemplazar por una política acotada + permissions boundary.
resource "aws_iam_role" "apply" {
  name = "${var.project}-gha-apply"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
          "${local.oidc_host}:sub" = flatten([
            for subject in local.github_subjects : [for env in var.github_environments : "${subject}:environment:${env}"]
          ])
        }
      }
    }]
  })
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "apply_admin" {
  #checkov:skip=CKV_AWS_274:Excepción temporal del reto (owner team-cloud, revisar 2026-12-31): reemplazar por política acotada + permissions boundary.
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
