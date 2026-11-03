# ADR-0003: VPC /16 en 3 AZs con subnets públicas /24 y privadas /20

## Contexto
El reto pide subnets públicas y privadas. Con el **VPC CNI** de EKS, cada pod consume una IP real de la subnet. Si las subnets quedan chicas, se agotan las IPs antes que la CPU.

## Decisión
- VPC `10.40.0.0/16` en **3 AZs** (`us-east-1a/b/c`).
- **Públicas /24** (`10.40.0-2.0/24`): solo ALB y NAT. `map_public_ip_on_launch = false`.
- **Privadas /20** (`10.40.16.0/20`, `.32`, `.48`; ~4.000 IPs por AZ): nodos y pods. El cluster no tiene nodos con IP pública.
- Los CIDR se calculan con `cidrsubnet()`, sin escribirlos a mano. Un test verifica que no se solapen.
- Tags de descubrimiento `kubernetes.io/role/elb` (públicas) e `internal-elb` (privadas), para que el controlador elija las subnets sin IDs fijos.
- El SG por defecto de la VPC queda **sin reglas**. **VPC Flow Logs** van a CloudWatch.

## Alternativas consideradas
- **2 AZs**: más barato, pero si cae una AZ se pierde el 50% de la capacidad y no hay quórum para repartir réplicas.
- **Subnets privadas /24**: alcanzan para el reto, pero limitan el crecimiento del cluster con VPC CNI.
- **Subnets para pods separadas (custom networking / prefix delegation)**: es la opción para clusters grandes. Aquí es complejidad innecesaria.

## Consecuencias
- Queda espacio libre en el /16 para subnets futuras: base de datos, endpoints, más AZs.
- El módulo acepta de 2 a 4 AZs, con validación.
