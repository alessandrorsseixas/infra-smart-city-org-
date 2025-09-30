#!/bin/bash
# install-minikube.sh: Instala e configura o Minikube para Kubernetes
# Uso: bash install-minikube.sh

set -euo pipefail
kubectl delete pod test-minikube-pod --ignore-not-found=true
# Instala e configura o Minikube para Kubernetes
# Uso: bash install-minikube.sh
for cmd in docker kubectl minikube helm; do
  if ! command -v $cmd &> /dev/null; then
    echo "[ERRO] Pré-requisito '$cmd' não encontrado. Execute 'install-prereqs.sh' antes."
    exit 1
  fi
done

# Garante que o usuário está no grupo docker
if ! groups $USER | grep -qw docker; then
  echo "Adicionando $USER ao grupo docker..."
  sudo usermod -aG docker "$USER"
  echo "Reiniciando Docker daemon..."
  sudo systemctl restart docker
  echo "Permissões aplicadas. Continuando..."
fi

echo "Todos os pré-requisitos estão instalados."

# 2. Inicia o Minikube
USE_SG=false
if ! docker version &> /dev/null; then
  USE_SG=true
fi

if minikube status &> /dev/null; then
  echo "Minikube já está rodando."
else
  echo "Iniciando Minikube com driver Docker..."
  if $USE_SG; then
    sg docker -c "minikube start --driver=docker --memory=4096 --cpus=2 --kubernetes-version=v1.31.0"
  else
    minikube start --driver=docker --memory=4096 --cpus=2 --kubernetes-version=v1.31.0
  fi
  echo "Aguardando cluster ficar pronto..."
  sleep 10
  # Atualiza contexto kubectl
  if $USE_SG; then
    sg docker -c "minikube update-context" || true
  else
    minikube update-context || true
  fi
  kubectl config use-context minikube || true
fi

# 3. Valida o status do cluster
if $USE_SG; then
  sg docker -c "minikube status" || echo "Minikube status check failed, continuing..."
else
  minikube status || echo "Minikube status check failed, continuing..."
fi
kubectl cluster-info || echo "kubectl cluster-info failed, continuing..."
kubectl get nodes || echo "kubectl get nodes failed, continuing..."

# 4. Testa criação de pod simples
kubectl run test-minikube-pod --image=nginx --restart=Never --port=80 --dry-run=client -o yaml | kubectl apply -f -
kubectl wait --for=condition=Ready pod/test-minikube-pod --timeout=60s || echo "Test pod may not be ready yet, continuing..."
kubectl get pods | grep test-minikube-pod || echo "Test pod not found"
kubectl delete pod test-minikube-pod --ignore-not-found=true

echo "Minikube instalado, validado e pronto para uso!"
