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

# Verifica permissões do Docker
USE_NEWGRP=false
if ! docker version &> /dev/null; then
  USE_NEWGRP=true
  echo "Permissões do Docker não disponíveis. Reiniciando script com newgrp para ativar grupo docker..."
  exec newgrp docker "$0" "$@"
fi

# 1. Instala pré-requisitos
./install-prereqs.sh "$@"

# 2. Instala/configura novo Minikube
./install-minikube.sh "$@"

# 4. Instala, valida e configura o certificado TLS
./install-cert.sh "$1" default

# 5. Instala e configura o Rancher
./install-rancher-minikube.sh "$1" cattle-system

echo "\nAmbiente Minikube com Rancher está pronto!\nAcesse: https://$1"

echo "\nAmbiente Minikube com Rancher está pronto!\nAcesse: https://$1"
