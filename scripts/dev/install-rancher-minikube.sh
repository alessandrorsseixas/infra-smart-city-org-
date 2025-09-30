#!/bin/bash
# install-rancher-minikube.sh: Instala Rancher no Minikube, configura domínio no /etc/hosts e valida tudo
# Uso: bash install-rancher-minikube.sh <dominio> [namespace]

set -euo pipefail

# 1. Checa pré-requisitos
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

# 2. Parâmetros
DOMAIN=${1:-rancher.local}
NAMESPACE=${2:-cattle-system}

# 3. Inicia Minikube se necessário
USE_SG=false
if ! docker version &> /dev/null; then
  USE_SG=true
fi

if ! minikube status &> /dev/null; then
  echo "Minikube não está rodando. Iniciando..."
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

# 4. Instala/valida Helm repo Rancher
if ! helm repo list | grep -q rancher-latest; then
  helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
fi
helm repo update

# 5. Cria namespace se não existir
kubectl get namespace "$NAMESPACE" &> /dev/null || kubectl create namespace "$NAMESPACE" || echo "kubectl create namespace failed, continuing..."

# 6. Instala/valida cert-manager
if ! kubectl get pods -n cert-manager 2>/dev/null | grep -q cert-manager; then
  echo "Instalando cert-manager..."
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml || echo "kubectl apply cert-manager failed, continuing..."
  kubectl wait --namespace cert-manager --for=condition=Ready pod --selector=app.kubernetes.io/instance=cert-manager --timeout=180s || echo "kubectl wait cert-manager failed, continuing..."
else
  echo "cert-manager já instalado."
fi

# 7. Instala Rancher via Helm
if ! helm list -n "$NAMESPACE" | grep -q rancher; then
  echo "Instalando Rancher..."
  helm install rancher rancher-latest/rancher \
    --namespace "$NAMESPACE" \
    --set hostname="$DOMAIN" \
    --set replicas=1 \
    --set ingress.tls.source=auto || echo "helm install rancher failed, continuing..."
else
  echo "Rancher já instalado."
fi

# 8. Aguarda Rancher ficar pronto
kubectl rollout status deployment/rancher -n "$NAMESPACE" --timeout=300s || echo "kubectl rollout status failed, continuing..."

# 9. Descobre IP do Minikube
if $USE_SG; then
  MINIKUBE_IP=$(sg docker -c "minikube ip" 2>/dev/null || echo "192.168.49.2")
else
  MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "192.168.49.2")
fi

# 10. Adiciona domínio ao /etc/hosts
if ! grep -q "$DOMAIN" /etc/hosts; then
  echo "Adicionando $DOMAIN ao /etc/hosts com IP $MINIKUBE_IP (requer sudo)..."
  echo "$MINIKUBE_IP $DOMAIN" | sudo tee -a /etc/hosts || echo "sudo tee failed, continuing..."
else
  echo "$DOMAIN já está em /etc/hosts."
fi

# 11. Valida acesso
kubectl get ingress -n "$NAMESPACE" || echo "kubectl get ingress failed, continuing..."
echo "Acesse https://$DOMAIN para finalizar configuração do Rancher."

# 12. Exibe senha bootstrap
echo ""
echo "Senha bootstrap inicial do Rancher:"
kubectl get secret --namespace "$NAMESPACE" bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}' 2>/dev/null || echo "kubectl get secret failed, Rancher may not be ready yet."


# 7. Instala Rancher via Helm
if ! helm list -n "$NAMESPACE" | grep -q rancher; then
  echo "Instalando Rancher..."
  helm install rancher rancher-latest/rancher \
    --namespace "$NAMESPACE" \
    --set hostname="$DOMAIN" \
    --set replicas=1 \
    --set ingress.tls.source=auto
# 7. Instala Rancher via Helm
# (Removido bloco duplicado)
  MINIKUBE_IP=$(minikube ip)
fi

# 10. Adiciona domínio ao /etc/hosts
if ! grep -q "$DOMAIN" /etc/hosts; then
  echo "Adicionando $DOMAIN ao /etc/hosts com IP $MINIKUBE_IP (requer sudo)..."
  echo "$MINIKUBE_IP $DOMAIN" | sudo tee -a /etc/hosts
else
  echo "$DOMAIN já está em /etc/hosts."
fi

# 11. Valida acesso
kubectl get ingress -n "$NAMESPACE"
echo "Acesse https://$DOMAIN para finalizar configuração do Rancher."

# 12. Exibe senha bootstrap
echo ""
echo "Senha bootstrap inicial do Rancher:"
kubectl get secret --namespace "$NAMESPACE" bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'