terraform {
  # >= 1.10 por el bloqueo nativo del backend S3 (use_lockfile), sin DynamoDB.
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }

  # bucket se inyecta con -backend-config (ver backend.hcl.example y el pipeline).
  backend "s3" {
    key          = "dev/us-east-1/platform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
