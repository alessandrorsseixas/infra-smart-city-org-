#!/bin/bash
# run.sh: Executa toda a configuração do zero até o Rancher funcional no Minikube
# Uso: bash run.sh <dominio-rancher>

set -euo pipefail

# Verifica se está rodando como root
if [[ $EUID -eq 0 ]]; then
  echo "Este script não deve ser executado como root. Execute como usuário normal."
  echo "O script solicitará sudo quando necessário."
  exit 1
fi

# 1. Instala pré-requisitos
./install-prereqs.sh "$@"

# 2. Deleta Minikube existente e instala/configura novo
echo "Deletando Minikube existente (se houver)..."
minikube delete --all || true

# Verifica permissões do Docker e re-exec se necessário para ativar grupo docker
if ! docker version &> /dev/null; then
  echo "Permissões do Docker não disponíveis para o usuário atual. Re-executando com newgrp docker para ativar grupo..."
  exec newgrp docker "$0" "$@"
fi

# 3. Instala/configura novo Minikube
./install-minikube.sh "$@"

# 4. Instala e configura o Ingress Controller
./install-ingress.sh "$@"

# 5. Instala, valida e configura o certificado TLS (passa o domínio como nome do certificado)
DOMAIN=${1:-rancher.local}
./install-cert.sh "$DOMAIN" default

# 6. Instala e configura o Rancher
./install-rancher-minikube.sh "$DOMAIN" cattle-system

echo "\nAmbiente Minikube com Rancher está pronto!\nAcesse: https://$DOMAIN"
