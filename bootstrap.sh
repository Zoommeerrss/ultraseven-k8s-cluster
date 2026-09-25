#!/bin/bash
set -e # Interrompe o script se qualquer comando falhar

echo "🏗️  Iniciando automação do Terraform para o Kind..."

# ==========================================
# 0. RESOLUÇÃO DE PERMISSÕES DO DOCKER (WSL)
# ==========================================
# Garante de forma transparente que o seu usuário consiga falar com o Docker sem travar por 'permission denied'
if [ -e "/var/run/docker.sock" ]; then
    echo "🐳 Ajustando permissões do socket do Docker..."
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
fi

# ==========================================
# 1. ATUALIZAÇÃO DOS PROVEDORES DO TERRAFORM
# ==========================================
echo "📦 Atualizando e validando provedores do Terraform..."
rm -rf .terraform .terraform.lock.hcl

# O uso do '-upgrade' força o Terraform a reavaliar os provedores do providers.tf do zero
terraform init -upgrade -input=false

# ==========================================
# 2. CRIAÇÃO DA INFRAESTRUTURA
# ==========================================
echo "🚀 Aplicando configurações de infraestrutura e subindo o Kind..."
terraform apply -auto-approve -input=false

# ==========================================
# 3. SINCRONIZAÇÃO E EXPORT DO KUBECONFIG
# ==========================================
echo "🔌 Sincronizando credenciais do cluster com o sistema..."

# Define o caminho do arquivo gerado pelo Terraform
LOCAL_KUBECONFIG="$(pwd)/.kube/config"

# Garante que a pasta global do Kubernetes existe e faz o backup/cópia do arquivo
mkdir -p "$HOME/.kube"
cp "$LOCAL_KUBECONFIG" "$HOME/.kube/config"

# Exporta a variável global para que o terminal atual e os subprocessos enxerguem o cluster
export KUBECONFIG="$HOME/.kube/config"

# ==========================================
# 4. FINALIZAÇÃO E INICIALIZAÇÃO DO K9S
# ==========================================
echo "--------------------------------------------------"
echo "✅ INFRAESTRUTURA APLICADA COM SUCESSO!"
echo "--------------------------------------------------"
echo "🌐 Cluster: ultraman-cluster"
echo "🔌 Banco: localhost:5432"
echo "🛠️  Kubeconfig configurado e unificado globalmente."
echo "🚀 Abrindo o K9s automaticamente no contexto do cluster..."
echo "--------------------------------------------------"

# Dispara o K9s olhando diretamente para a configuração oficial unificada
k9s
