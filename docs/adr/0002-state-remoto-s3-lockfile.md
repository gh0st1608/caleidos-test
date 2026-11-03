# ADR-0002: State remoto en S3 con lock nativo y bootstrap separado

## Contexto
El pipeline y las personas deben compartir el state de forma segura. El state tiene datos sensibles: endpoints, ARNs y, a veces, valores de outputs.

## Decisión
- Backend **S3 con `use_lockfile = true`**, el lock nativo disponible desde Terraform 1.10. No se usa tabla DynamoDB.
- El bucket tiene:
  - versionado,
  - cifrado KMS,
  - Public Access Block,
  - política que niega conexiones sin TLS,
  - lifecycle para versiones antiguas,
  - `prevent_destroy`.
- El bucket y los roles OIDC del pipeline viven en el stack `live/bootstrap`, con state local y aplicado una sola vez. Así se resuelve el problema del huevo y la gallina: el bucket no puede guardar el state de su propia creación.
- La clave del state sigue el patrón `<entorno>/<región>/<stack>/terraform.tfstate`. El bucket se pasa con `-backend-config`, para no dejar valores de cuenta en el código.

## Alternativas consideradas
- **S3 + DynamoDB**: es el patrón clásico, hoy marcado como deprecado por HashiCorp. Agrega un recurso más.
- **HCP Terraform / Terraform Cloud**: resuelve el state y los runs, pero agrega una dependencia externa y costo.

## Consecuencias
- El bootstrap queda con state local, que hay que resguardar o migrar al bucket después de crearlo.
- Requiere Terraform ≥ 1.10 (`required_version`).
