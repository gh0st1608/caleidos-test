# ADR-0013: Validación automática y excepciones documentadas en el código

## Contexto
El código de infraestructura debe pasar controles de calidad y seguridad antes de llegar a AWS. Algunos hallazgos son aceptables en dev y hay que dejarlos registrados.

## Decisión
- En cada Pull Request corren:
  - `terraform fmt`, `validate`, `tflint` (con el ruleset de AWS),
  - `terraform test` con `mock_provider` (sin credenciales; valida AZs, NATs y que los CIDR no se solapen),
  - **Checkov**, que **falla con cualquier hallazgo**.
- Las excepciones se declaran **en el código**, junto al recurso, con su razón: `#checkov:skip=ID:razón`. Ejemplos: endpoint público de EKS en dev, retención de logs de 30 días, rol de apply con permisos de administrador.
- Versiones fijadas: providers (`~> 6.0` AWS, `~> 3.0` Helm), `.terraform.lock.hcl` para varias plataformas y chart con versión exacta.

## Alternativas consideradas
- **Lista de excepciones en un archivo central**: se pierde el contexto de por qué se aceptó cada una.
- **Checkov solo informativo** (soft-fail): las excepciones se acumulan sin que nadie las decida.

## Consecuencias
- Resultado local: Checkov sobre Terraform con 146 controles aprobados, 0 fallidos y 16 excepciones justificadas. Los 5 tests pasan y tflint no reporta hallazgos.
- Cada excepción nueva queda visible en el diff del PR, donde se revisa.
