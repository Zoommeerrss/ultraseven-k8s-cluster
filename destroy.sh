#!/bin/bash
set -e # Interrompe o script se qualquer comando falhar

echo "🔥 Iniciando desestruturação completa da infraestrutura..."

# ==========================================
# 0. RESOLUÇÃO DE PERMISSÕES DO DOCKER (WSL)
# ==========================================
if [ -e "/var/run/docker.sock" ]; then
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
fi

# ==========================================
# 1. DESTRUIÇÃO DOS RECURSOS VIA TERRAFORM
# ==========================================
echo "🗑️  Removendo cluster Kind e manifestos do Kubernetes..."

# Força o reset dos caches locais e baixa a versão correta do provedor antes de destruir
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade -input=false

# O comando destroy remove tudo o que foi declarado no main.tf sem pedir confirmação (-auto-approve)
terraform destroy -auto-approve -input=false

# ==========================================
# 2. LIMPEZA DE ARQUIVOS E CREDENCIAIS LOCAL
# ==========================================
echo "🧹 Limpando arquivos temporários e kubeconfig..."

# Remove o arquivo kubeconfig local gerado pelo Terraform
rm -rf ./.kube

# Remove o arquivo de configuração unificado global se ele pertencer ao ultraman-cluster
# (Evita deixar contextos órfãos no seu sistema)
if [ -f "$HOME/.kube/config" ]; then
    rm -f "$HOME/.kube/config"
    echo "✨ Arquivo kubeconfig global limpo."
fi

# ==========================================
# 3. FINALIZAÇÃO
# ==========================================
echo "--------------------------------------------------"
echo "💥 INFRAESTRUTURA REMOVIDA COMPLETAMENTE!"
echo "--------------------------------------------------"
echo "🐳 Todos os containers do Kind foram apagados do Docker."
echo "🧹 Pastas temporárias limpas."
echo "--------------------------------------------------"
