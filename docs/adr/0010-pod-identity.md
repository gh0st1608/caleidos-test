# ADR-0010: EKS Pod Identity en lugar de IRSA

## Contexto
El Load Balancer Controller necesita permisos de AWS para crear ALBs y target groups. Los pods no deben usar el rol del nodo.

## Decisión
- Rol IAM con trust a `pods.eks.amazonaws.com`, asociado a la ServiceAccount con `aws_eks_pod_identity_association`.
- La política IAM es la **oficial del proyecto**, fijada a la versión del chart (`iam_policy.json` del tag `v3.6.0`).
- El agente `eks-pod-identity-agent` se instala como add-on (ADR-0008).

## Alternativas consideradas
- **IRSA** (OIDC provider + anotación en la SA): es el método anterior. Exige un OIDC provider por cluster y trust policies atadas a su URL, y no se puede reutilizar entre clusters.
- **Credenciales en el rol del nodo**: todos los pods del nodo tendrían esos permisos. Esto no cumple el mínimo privilegio.

## Consecuencias
- No hace falta OIDC provider ni anotaciones. El mismo rol sirve para otros clusters sin cambiar la trust policy.
- Junto con IMDSv2 `hop_limit = 1` (ADR-0007), un pod sin asociación no tiene ninguna credencial de AWS. Por eso el chart recibe `region` y `vpcId` de forma explícita.
