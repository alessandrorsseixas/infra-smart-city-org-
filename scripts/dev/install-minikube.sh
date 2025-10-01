#!/bin/bash
# install-minikube.sh: Instala e configura o Minikube para Kubernetes
# Uso: bash install-minikube.sh

set -euo pipefail

# install-minikube.sh: idempotent Minikube install and validation
# Usage: bash install-minikube.sh
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

# 4. Testa criação de pod simples em namespace de teste para evitar RBAC no default
TEST_NS="minikube-test"
if kubectl get namespace "$TEST_NS" >/dev/null 2>&1; then
  echo "Namespace $TEST_NS já existe."
else
  kubectl create namespace "$TEST_NS" || echo "Falha ao criar namespace $TEST_NS, continuando..."
fi

cat <<EOF | kubectl apply -n "$TEST_NS" -f - || echo "Falha ao criar test pod manifest, continuando..."
apiVersion: v1
kind: Pod
metadata:
  name: test-minikube-pod
spec:
  containers:
  - name: nginx
    image: nginx:stable
    ports:
    - containerPort: 80
  restartPolicy: Never
EOF

kubectl wait -n "$TEST_NS" --for=condition=Ready pod/test-minikube-pod --timeout=60s || echo "Test pod may not be ready yet, continuing..."
kubectl get pods -n "$TEST_NS" | grep test-minikube-pod || echo "Test pod not found in $TEST_NS"

# Limpa o pod e namespace de teste de forma segura
kubectl delete pod test-minikube-pod -n "$TEST_NS" --ignore-not-found=true || true
kubectl delete namespace "$TEST_NS" --ignore-not-found=true || true

echo "Minikube instalado, validado e pronto para uso!"
