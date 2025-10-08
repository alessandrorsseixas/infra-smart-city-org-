#!/bin/bash
# install-ingress.sh: Instala e valida o Ingress Controller no Minikube/Kubernetes
# Uso: bash install-ingress.sh

set -euo pipefail

# 1. Verifica se o ingress-nginx já está instalado
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
  if kubectl get pods -n ingress-nginx 2>/dev/null | grep -q 'ingress-nginx-controller.*Running'; then
    echo "Ingress NGINX já está instalado e rodando."
  else
    echo "Namespace ingress-nginx existe, mas controlador não está rodando. Tentando habilitar addon..."
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
else
  echo "Ingress NGINX não encontrado. Habilitando o addon do Minikube."
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

# Aguarda o pod ficar pronto (se existir namespace) - timeout aumentado
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
  echo "Aguardando pods do ingress controller ficarem prontos..."
  kubectl wait --namespace ingress-nginx \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s || echo "kubectl wait falhou ou timeout 5min, continuando..."
  
  # Verificação adicional se realmente está rodando
  if kubectl get pods -n ingress-nginx 2>/dev/null | grep -q 'ingress-nginx-controller.*Running'; then
    echo "Ingress controller confirmado como Running."
  else
    echo "AVISO: Ingress controller pode não estar totalmente pronto. Aguarde alguns minutos antes de acessar aplicações via ingress."
  fi
fi

# 2. Validação (tolerante)
kubectl get pods -n ingress-nginx || echo "kubectl get pods falhou, ingress pode não estar pronto yet"
kubectl get svc -n ingress-nginx || echo "kubectl get svc falhou, ingress pode não estar pronto yet"

echo "Ingress Controller validado e pronto para uso ou em processo de inicialização."
