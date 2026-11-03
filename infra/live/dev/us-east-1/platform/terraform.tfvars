# Valores específicos del entorno (sin secretos).
project             = "acme-txn"
environment         = "dev"
region              = "us-east-1"
owner               = "team-cloud"
cost_center         = "cc-1001"
data_classification = "confidential"
repository          = "caleidos-test"

vpc_cidr           = "10.40.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
single_nat_gateway = false # HA: un NAT por AZ

kubernetes_version = "1.35"

node_group = {
  instance_types = ["t3.medium"]
  min_size       = 3
  max_size       = 6
  desired_size   = 3 # un nodo por AZ
}

# Restringir a la IP pública del equipo / runners en un entorno real.
eks_public_access_cidrs = ["0.0.0.0/0"]

# Los ARNs de la cuenta (eks_admin/viewer_principal_arns) NO se versionan:
# - en local: local.auto.tfvars (ignorado por git, ver local.auto.tfvars.example)
# - en el pipeline: TF_VAR_* desde las variables del repo en GitHub
