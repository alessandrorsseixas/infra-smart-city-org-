#!/bin/bash
# install-prereqs.sh: Instala todos os pré-requisitos para cluster Kubernetes com Minikube
# Uso: bash install-prereqs.sh

set -euo pipefail

# 1. Atualiza pacotes
sudo apt-get update

# 2. Instala dependências básicas
sudo apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release software-properties-common

# 3. Instala Docker
if ! command -v docker &> /dev/null; then
  echo "Instalando Docker..."
  curl -fsSL https://get.docker.com | sudo bash
else
  echo "Docker já instalado."
fi

# Garante que o usuário está no grupo docker
if ! groups $USER | grep -qw docker; then
  echo "Adicionando $USER ao grupo docker..."
  sudo usermod -aG docker "$USER"
  echo "Reiniciando Docker daemon..."
  sudo systemctl restart docker
  echo "Permissões aplicadas. Continuando..."
fi

  # Verifica se o usuário está no grupo docker na sessão atual
  if ! groups | grep -qw docker; then
    echo "Re-execute este terminal com: newgrp docker"
  fi
# 4. Instala kubectl
if ! command -v kubectl &> /dev/null; then
  echo "Instalando kubectl..."
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
else
  echo "kubectl já instalado."
fi

# 5. Instala Minikube
if ! command -v minikube &> /dev/null; then
  echo "Instalando Minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64
else
  echo "Minikube já instalado."
fi

# 6. Instala Helm
if ! command -v helm &> /dev/null; then
  echo "Instalando Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "Helm já instalado."
fi

# 7. Validação das instalações
for cmd in docker kubectl minikube helm; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd não instalado corretamente."
    exit 1
  fi
  echo "$cmd instalado com sucesso."
done

echo "Todos os pré-requisitos foram instalados e validados. Permissões do Docker aplicadas automaticamente."

# 8. Configuração do Docker para pelo menos 2 CPUs
DOCKER_CONFIG_FILE="/etc/docker/daemon.json"
if command -v jq &> /dev/null; then
  if [ -w "$DOCKER_CONFIG_FILE" ] || sudo test -w "$DOCKER_CONFIG_FILE"; then
    if ! grep -q '"default-cpus"' "$DOCKER_CONFIG_FILE"; then
      echo "Configurando Docker para usar pelo menos 2 CPUs..."
      TMPFILE=$(mktemp)
      if [ -s "$DOCKER_CONFIG_FILE" ]; then
        sudo jq '. + {"default-cpus": 2}' "$DOCKER_CONFIG_FILE" > "$TMPFILE" && sudo mv "$TMPFILE" "$DOCKER_CONFIG_FILE"
      else
        echo '{"default-cpus": 2}' | sudo tee "$DOCKER_CONFIG_FILE" > /dev/null
      fi
      sudo systemctl restart docker
      echo "Docker configurado para usar pelo menos 2 CPUs."
    else
      echo "Docker já configurado para usar pelo menos 2 CPUs."
    fi
  else
    echo "Não foi possível configurar CPUs do Docker automaticamente. Configure manualmente em /etc/docker/daemon.json."
  fi
else
  echo "jq não encontrado. Instale o pacote jq para configuração automática do Docker."
fi
