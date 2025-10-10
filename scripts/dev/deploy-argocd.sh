#!/bin/bash
# deploy-argocd.sh: Instala o ArgoCD via HelmChart ou Helm direto, conforme ambiente

set -euo pipefail

YAML_PATH="$(dirname "$0")/../../k8s/deploy.argocd.yaml"
NAMESPACE="argocd"

# Verifica se kubectl está disponível
if ! command -v kubectl &> /dev/null; then
  echo "kubectl não encontrado. Instale o kubectl antes de prosseguir."
  exit 1
fi

# Verifica se helm está disponível
if ! command -v helm &> /dev/null; then
  echo "helm não encontrado. Instale o helm antes de prosseguir."
  exit 1
fi

# Verifica se CRD HelmChart está instalado
if kubectl get crd helmcharts.helm.cattle.io &> /dev/null; then
  echo "CRD HelmChart encontrado. Instalando via Rancher HelmChart..."
  if [ ! -f "$YAML_PATH" ]; then
    echo "Arquivo YAML do HelmChart não encontrado: $YAML_PATH"
    exit 1
  fi
  kubectl apply -f "$YAML_PATH"
  kubectl get helmchart -A
  echo "ArgoCD HelmChart solicitado. Acompanhe a instalação pelo Rancher ou via kubectl na namespace definida."
else
  echo "CRD HelmChart não encontrado. Instalando ArgoCD diretamente via Helm..."
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update
  kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
  helm install argocd argo/argo-cd --namespace $NAMESPACE
  echo "ArgoCD instalado diretamente via Helm na namespace $NAMESPACE."
fi
