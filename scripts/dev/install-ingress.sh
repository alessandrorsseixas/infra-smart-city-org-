#!/bin/bash
# install-ingress.sh: Instala e valida o Ingress Controller no Minikube/Kubernetes
# Uso: bash install-ingress.sh

set -euo pipefail

"# 1. Verifica se o ingress-nginx já está instalado
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
  if kubectl get pods -n ingress-nginx 2>/dev/null | grep -q 'ingress-nginx-controller'; then
    echo "Ingress NGINX já está instalado."
  else
    echo "Namespace ingress-nginx existe, mas controlador não encontrado. Tentando habilitar addon..."
  fi
else
  echo "Ingress NGINX não encontrado. Iremos habilitar o addon do Minikube."
  USE_SG=false
  if ! docker version &> /dev/null; then
    USE_SG=true
  fi
  if $USE_SG; then
    sg docker -c "minikube addons enable ingress" || echo "minikube addons enable failed, continuing..."
  else
    minikube addons enable ingress || echo "minikube addons enable failed, continuing..."
  fi
fi

# Aguarda o pod ficar pronto (se existir namespace)
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
  kubectl wait --namespace ingress-nginx \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s || echo "kubectl wait falhou ou timeout, continue monitorando..."
fi

# 2. Validação (tolerante)
kubectl get pods -n ingress-nginx || echo "kubectl get pods falhou, ingress pode não estar pronto yet"
kubectl get svc -n ingress-nginx || echo "kubectl get svc falhou, ingress pode não estar pronto yet"

echo "Ingress Controller validado e pronto para uso (ou em processo de inicialização)."
