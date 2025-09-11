# Smart City Organization - Infrastructure

Aplicação para construção da infraestrutura da plataforma Smart City Organization.

## Visão Geral

Este repositório contém toda a infraestrutura necessária para deploy da aplicação Smart City Organization usando Kubernetes. A infraestrutura inclui componentes essenciais como bancos de dados, message brokers, ferramentas de automação e serviços de autenticação.

## Estrutura do Projeto

```
├── k8s/                          # Configurações Kubernetes
│   ├── base/                     # Recursos base do Kubernetes
│   │   └── n8n/                 # Configurações do N8N
│   └── overlays/                # Overlays específicos por ambiente
│       └── dev/                 # Configurações para desenvolvimento
├── scripts/                     # Scripts de instalação e configuração
│   └── dev/                     # Scripts para ambiente de desenvolvimento
```

## Componentes da Infraestrutura

### Bancos de Dados
- **PostgreSQL**: Banco de dados principal
- **MongoDB**: Banco de dados NoSQL para dados não relacionais
- **Redis**: Cache e session store

### Message Broker
- **RabbitMQ**: Sistema de mensageria para comunicação entre microserviços

### Automação e Orquestração
- **N8N**: Plataforma de automação de workflows

### Autenticação
- **Keycloak**: Servidor de identidade e gerenciamento de acesso

### Servidor MCP
- **MCP Server**: Model Context Protocol Server

## Pré-requisitos

Antes de executar os scripts de instalação, certifique-se de ter:

- Docker instalado
- Minikube ou cluster Kubernetes disponível
- kubectl configurado
- Helm (se necessário)

## Instalação Rápida

### 1. Instalar Pré-requisitos
```bash
./scripts/dev/install-prereqs.sh
```

### 2. Instalar Minikube
```bash
./scripts/dev/install-minikube.sh
```

### 3. Instalar Rancher no Minikube
```bash
./scripts/dev/install-rancher-minikube.sh
```

### 4. Configurar Ingress
```bash
./scripts/dev/install-ingress.sh
```

### 5. Instalar Certificados
```bash
./scripts/dev/install-cert.sh
```

## Deploy dos Serviços

### Deploy Completo
Para fazer o deploy de todos os serviços de uma vez:
```bash
./k8s/scripts/dev/deploy-all.sh
```

### Deploy Individual

Você também pode fazer o deploy de serviços individuais:

```bash
# PostgreSQL
./k8s/scripts/dev/deploy-postgres.sh

# MongoDB
./k8s/scripts/dev/deploy-mongo.sh

# Redis
./k8s/scripts/dev/deploy-redis.sh

# RabbitMQ
./k8s/scripts/dev/deploy-rabbitmq.sh

# Keycloak
./k8s/scripts/dev/deploy-keycloak.sh

# N8N
./k8s/scripts/dev/deploy-n8n.sh

# MCP Server
./k8s/scripts/dev/deploy-mcp-server.sh
```

## Configuração do Ambiente

### Desenvolvimento

Para executar o ambiente de desenvolvimento:
```bash
./scripts/dev/run.sh
```

## Estrutura Kubernetes

O projeto utiliza Kustomize para gerenciar configurações específicas por ambiente:

- `k8s/base/`: Contém as configurações base dos recursos Kubernetes
- `k8s/overlays/dev/`: Contém as customizações específicas para o ambiente de desenvolvimento

## Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## Suporte

Para suporte e dúvidas, por favor abra uma [issue](https://github.com/alessandrorsseixas/infra-smart-city-org-/issues) no repositório.
