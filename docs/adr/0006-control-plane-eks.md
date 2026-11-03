# ADR-0006: Control plane EKS con Access Entries, KMS y logs completos

## Contexto
El reto pide un cluster EKS. Hay que decidir cómo se accede, cómo se protegen los Secrets y qué tan expuesto queda el API server.

## Decisión
- **Versión 1.35**, con `upgrade_policy = STANDARD`. Así nunca se pasa en silencio al soporte extendido, que cuesta ~6× más por hora. Obliga a planificar los upgrades.
- **Autenticación con EKS Access Entries** (`authentication_mode = "API"`), sin el ConfigMap `aws-auth`. Los admins y viewers se declaran como listas de ARNs en Terraform, con políticas gestionadas (`AmazonEKSClusterAdminPolicy` / `AmazonEKSAdminViewPolicy`).
- **Envelope encryption de Secrets** con una KMS key propia, con rotación activada.
- **Los 5 tipos de log** del control plane van a un log group creado por Terraform, con retención definida. Si lo creara EKS, quedaría sin expiración.
- **Endpoint privado + público**. El público se acota con `public_access_cidrs`, porque los runners de GitHub y el evaluador necesitan llegar al API server.

## Alternativas consideradas
- **ConfigMap `aws-auth`**: es el mecanismo legado. Se edita a mano, no se audita con IAM y un error deja a todos sin acceso.
- **Endpoint solo privado**: es lo correcto en producción, pero exige VPN, bastión o runners self-hosted dentro de la VPC.
- **ECS / Fargate**: es más simple de operar, pero el reto pide EKS de forma explícita.

## Consecuencias
- En dev, `public_access_cidrs = 0.0.0.0/0` (protegido por IAM). En prod se restringe a los CIDR corporativos y de los runners. Está documentado como excepción de Checkov.
- El rol de *plan* del pipeline necesita acceso de lectura al cluster para refrescar el `helm_release`. Se le da como viewer mediante access entry.
