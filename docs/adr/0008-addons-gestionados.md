# ADR-0008: Add-ons gestionados por EKS, incluido metrics-server

## Contexto
El HPA necesita la Metrics API. El cluster necesita CNI, DNS, kube-proxy y el agente de Pod Identity.

## Decisión
- Se instalan como **EKS managed add-ons** desde Terraform: `vpc-cni`, `kube-proxy`, `coredns`, `eks-pod-identity-agent` y `metrics-server`.
- Versión: la **default compatible** con la versión de Kubernetes (`data.aws_eks_addon_version` con `most_recent = false`). Es la que AWS valida para esa versión.
- `vpc-cni` se configura con `enableNetworkPolicy = "true"`, para aplicar la NetworkPolicy sin instalar Calico.
- Los add-ons dependen del node group: `coredns` y `metrics-server` necesitan nodos para quedar `ACTIVE`.

## Alternativas consideradas
- **Instalar `metrics-server` con Helm o manifest**: funciona, pero es una pieza más que mantener. Como add-on, AWS gestiona su compatibilidad.
- **Fijar versiones exactas**: el resultado es más reproducible, pero hay que actualizarlas a mano en cada upgrade del cluster.
- **Calico para NetworkPolicy**: es más completo, pero el soporte nativo del VPC CNI basta para un default-deny.

## Consecuencias
- Un upgrade de Kubernetes arrastra los add-ons a su versión compatible en el mismo `apply`.
- `resolve_conflicts = OVERWRITE`: Terraform es la fuente de verdad y los cambios manuales se sobrescriben.
