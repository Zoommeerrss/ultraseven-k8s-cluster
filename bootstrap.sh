#!/bin/bash
set -e # Interrompe o script se qualquer comando falhar

echo "🏗️  Iniciando automação do Terraform para o Kind..."

# ==========================================
# 0. RESOLUÇÃO DE PERMISSÕES DO DOCKER (WSL)
# ==========================================
if [ -e "/var/run/docker.sock" ]; then
    echo "🐳 Ajustando permissões do socket do Docker..."
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
fi

# ==========================================
# 1. ATUALIZAÇÃO DOS PROVEDORES DO TERRAFORM
# ==========================================
echo "📦 Atualizando e validando provedores do Terraform..."
rm -rf .terraform .terraform.lock.hcl
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
LOCAL_KUBECONFIG="$(pwd)/.kube/config"
mkdir -p "$HOME/.kube"
cp "$LOCAL_KUBECONFIG" "$HOME/.kube/config"
export KUBECONFIG="$HOME/.kube/config"

# ==========================================
# 4. DISPARANDO A AUTOMAÇÃO COM ANSIBLE (PLUS)
# ==========================================
echo "🤖 Executando automações de DevOps com Ansible..."

# O ansible-setup.sh agora é o único responsável por validar,
# instalar e rodar o playbook no contexto correto da pasta ansible/
./ansible-setup.sh

# ==========================================
# 5. FINALIZAÇÃO E PRÓXIMOS PASSOS
# ==========================================
echo "--------------------------------------------------"
echo "✅ ESTEIRA DE DEVOPS CONCLUÍDA COM SUCESSO!"
echo "--------------------------------------------------"
echo "🌐 Cluster Kubernetes provisionado e configurado."
echo "🤖 Ansible aplicou todas as definições da pasta /settings."
echo ""
echo "👉 PRÓXIMO PASSO: Digite o comando abaixo para gerenciar o cluster:"
echo "   k9s"
echo "--------------------------------------------------"