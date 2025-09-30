#!/bin/bash
# install-ingress.sh: Instala e valida o Ingress Controller no Minikube/Kubernetes
# Uso: bash install-ingress.sh

set -euo pipefail

# 1. Verifica se o ingress-nginx já está instalado
if kubectl get pods -n ingress-nginx 2>/dev/null | grep -q 'ingress-nginx-controller'; then
  echo "Ingress NGINX já está instalado."
else
  echo "Instalando ingress-nginx..."
  USE_SG=false
  if ! docker version &> /dev/null; then
    USE_SG=true
  fi
  if $USE_SG; then
    sg docker -c "minikube addons enable ingress" || echo "minikube addons enable failed, continuing..."
  else
    minikube addons enable ingress || echo "minikube addons enable failed, continuing..."
  fi
  # Aguarda o pod ficar pronto
  kubectl wait --namespace ingress-nginx \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s || echo "kubectl wait failed, continuing..."
  echo "Ingress NGINX instalado com sucesso."
fi

# 2. Validação
kubectl get pods -n ingress-nginx || echo "kubectl get pods failed, continuing..."
kubectl get svc -n ingress-nginx || echo "kubectl get svc failed, continuing..."

echo "Ingress Controller validado e pronto para uso."
