# ADR-0012: Controlador con Helm en Terraform; aplicación con Kustomize

## Contexto
Hay dos ciclos de vida distintos: la **plataforma** (cluster, controlador, IAM) cambia poco y la gestiona el equipo de plataforma. La **aplicación** cambia seguido y la gestiona el equipo de producto.

## Decisión
- El Load Balancer Controller se instala con `helm_release` **dentro de Terraform**, porque depende de recursos de AWS creados en el mismo stack (rol IAM, Pod Identity, SG).
- El provider Helm se autentica con `exec` (`aws eks get-token`), sin guardar tokens en el state.
- La aplicación (Deployment, Service, Ingress, HPA, PDB, NetworkPolicy) se gestiona con **Kustomize**: una base, un overlay `dev` y componentes opcionales (`stress-sidecar`, `https`). La despliega un workflow aparte.

## Alternativas consideradas
- **Todo en Terraform** (incluidos los manifests de la app): un solo flujo, pero cada cambio de la app pasaría por el plan de la infraestructura.
- **GitOps (Argo CD / Flux)**: es lo ideal a escala, pero agrega otro sistema que instalar y operar en el reto.
- **Separar el controlador en otro stack**: evita configurar el provider Helm con un cluster que se crea en el mismo `apply`, pero agrega un state más.

## Consecuencias
- Riesgo conocido: un provider configurado con un cluster que se crea en el mismo `apply`. El `depends_on` y la autenticación `exec` (token pedido en el momento) lo mitigan. Si crece, se divide en dos stacks.
- La app se despliega y revierte sin tocar Terraform (`kubectl rollout undo`).
