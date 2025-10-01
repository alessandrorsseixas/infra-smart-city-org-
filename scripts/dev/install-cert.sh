#!/bin/bash
# install-cert.sh: Instala, valida e configura um certificado TLS para uso em Minikube/Kubernetes
# Uso: bash install-cert.sh <NOME_CERT> <NAMESPACE>

set -euo pipefail

CERT_NAME=${1:-my-cert}
NAMESPACE=${2:-default}
KEY_FILE="${CERT_NAME}.key"
CRT_FILE="${CERT_NAME}.crt"

# Cria namespace se não existir (tolerante)
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace $NAMESPACE não existe. Criando..."
  kubectl create namespace "$NAMESPACE" || echo "Falha ao criar namespace $NAMESPACE, continuando..."
fi

# 1. Gerar certificado autoassinado somente se não existir
if [ -f "$KEY_FILE" ] || [ -f "$CRT_FILE" ]; then
  echo "Arquivo de certificado ($CRT_FILE) ou chave ($KEY_FILE) já existe. Pulando geração."
else
  echo "Gerando certificado autoassinado: $CRT_FILE"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" -out "$CRT_FILE" \
    -subj "/CN=${CERT_NAME}.local"
  echo "Certificado autoassinado gerado: $CRT_FILE"
fi

# 2. Criar secret TLS no Kubernetes somente se não existir ou atualizar
if kubectl get secret "$CERT_NAME" --namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Secret TLS $CERT_NAME já existe no namespace $NAMESPACE. Atualizando com arquivos locais..."
  kubectl create secret tls "$CERT_NAME" --key "$KEY_FILE" --cert "$CRT_FILE" --namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - || echo "Falha ao atualizar secret TLS, continuando..."
else
  echo "Criando secret TLS $CERT_NAME no namespace $NAMESPACE..."
  kubectl create secret tls "$CERT_NAME" --key "$KEY_FILE" --cert "$CRT_FILE" --namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - || echo "Falha ao criar secret TLS, continuando..."
fi

# 3. Validar secret
if kubectl get secret "$CERT_NAME" --namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Secret $CERT_NAME criado/atualizado com sucesso no namespace $NAMESPACE."
else
  echo "Secret $CERT_NAME não encontrado. Houve um problema ao criar/atualizar o secret."
fi

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
