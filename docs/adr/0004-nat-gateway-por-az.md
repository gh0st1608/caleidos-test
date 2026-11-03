# ADR-0004: Un NAT Gateway por AZ

## Contexto
Los nodos en subnets privadas necesitan salir a Internet para descargar imágenes, llamar a APIs de AWS y registrarse en el cluster. El NAT Gateway es un recurso **zonal**.

## Decisión
- Un NAT Gateway (con su EIP) **por AZ**, y **una tabla de rutas privada por AZ** que apunta a su propio NAT.
- La variable `single_nat_gateway = true` deja un solo NAT para entornos efímeros, donde pesa más el costo.

## Alternativas consideradas
- **Un solo NAT**: ahorra ~USD 33/mes por NAT, más USD 0.045/GB procesado, pero es un punto único de falla. Si cae su AZ, las otras dos se quedan sin salida. Además, el tráfico entre AZs se cobra.
- **VPC Endpoints** (ECR, S3, STS) sin NAT: reducen costo y superficie de ataque. Es el siguiente paso natural, pero suma ~6 endpoints de interfaz y no reemplaza el acceso a Docker Hub.

## Consecuencias
- Si falla una AZ, el egreso de las otras sigue funcionando.
- Es el componente más caro del entorno (3 × NAT). Está documentado, y por eso existe la variable para bajar a uno.
