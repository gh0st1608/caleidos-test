# ADR-0009: Exposición con ALB vía AWS Load Balancer Controller (target-type ip)

## Contexto
El reto pide exponer nginx con un Service y un balanceador, con HTTPS opcional, y demostrar que el tráfico se reparte entre pods.

## Decisión
- Se instala el **AWS Load Balancer Controller** (chart 3.6.0). Un `Ingress` con `ingressClassName: alb` crea un **ALB internet-facing** en las subnets públicas.
- **`target-type: ip`**: el ALB registra directamente las IPs de los pods (posible con VPC CNI) y balancea **pod por pod**, sin pasar por kube-proxy ni por NodePort.
- La app tiene un `Service` ClusterIP, que es lo que el Ingress usa para descubrir los endpoints.
- El health check apunta a `/healthz`. El `deregistration_delay` es de 30 s y el pod espera 10 s en `preStop`, para drenar conexiones sin cortes en los rollouts.
- **HTTPS** es opcional, como un componente de Kustomize: listener 443, redirect 80 → 443, política TLS 1.3 y certificado ACM descubierto por hostname.

## Alternativas consideradas
- **Service `type: LoadBalancer`** (NLB/CLB): es lo más simple, pero trabaja en L4. No da rutas, TLS gestionado ni health checks HTTP. El CLB está obsoleto.
- **`target-type: instance`**: pasa por NodePort y kube-proxy. Agrega un salto y el ALB no ve los pods, solo los nodos.
- **ingress-nginx detrás de un NLB**: es otro componente que operar y escalar. Además, ingress-nginx terminó su mantenimiento en 2026.

## Consecuencias
- La demo de balanceo es directa: cada request la responde un pod distinto, que muestra su nombre, IP y nodo.
- El ALB lo crea el controlador, no Terraform. Por eso, antes de destruir la infraestructura hay que borrar el Ingress. `scripts/destroy.sh` sigue ese orden.
