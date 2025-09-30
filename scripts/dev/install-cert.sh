#!/bin/bash
# install-cert.sh: Instala, valida e configura um certificado TLS para uso em Minikube/Kubernetes
# Uso: bash install-cert.sh <NOME_CERT> <NAMESPACE>

set -euo pipefail

CERT_NAME=${1:-my-cert}
NAMESPACE=${2:-default}
KEY_FILE="${CERT_NAME}.key"
CRT_FILE="${CERT_NAME}.crt"

# 1. Gerar certificado autoassinado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$KEY_FILE" -out "$CRT_FILE" \
  -subj "/CN=${CERT_NAME}.local"
echo "Certificado autoassinado gerado: $CRT_FILE"

# 2. Criar secret TLS no Kubernetes
kubectl create secret tls "$CERT_NAME" \
  --key "$KEY_FILE" --cert "$CRT_FILE" \
  --namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - || echo "kubectl create secret failed, continuing..."

# 3. Validar secret
kubectl get secret "$CERT_NAME" --namespace "$NAMESPACE" || echo "kubectl get secret failed, continuing..."

# 4. Exemplo de configuração de Ingress (opcional)
cat <<EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${CERT_NAME}-ingress
  namespace: $NAMESPACE
spec:
  tls:
  - hosts:
    - ${CERT_NAME}.local
    secretName: $CERT_NAME
  rules:
  - host: ${CERT_NAME}.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: <NOME_DO_SERVICO>
            port:
              number: 80
EOF

echo "Arquivo de exemplo de Ingress impresso acima. Substitua <NOME_DO_SERVICO> pelo nome do seu serviço."
