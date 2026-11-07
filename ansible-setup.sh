#!/bin/bash
set -e

echo "🤖 [Ansible Setup] Iniciando validação do ambiente de automação..."

# ==========================================
# 1. VALIDAÇÃO E INSTALAÇÃO DE DEPENDÊNCIAS
# ==========================================
if ! command -v ansible-playbook &> /dev/null; then
    echo "⚠️  Ansible não encontrado. Instalando dependências do sistema..."
    sudo apt-get update -y
    # Garante o Ansible e o gerenciador de pacotes Python do Ubuntu
    sudo apt-get install -y ansible python3-pip python3-kubernetes
fi

# Instala coleções necessárias do Ansible de forma resiliente
echo "📦 Validando coleções e módulos do ecossistema Kubernetes..."
ansible-galaxy collection install kubernetes.core --get-permanent-id 2>/dev/null || ansible-galaxy collection install kubernetes.core

# Instala jsonpatch tratando restrições de ambiente moderno do Ubuntu (PEP 668)
pip install jsonpatch --quiet --break-system-packages 2>/dev/null || pip install jsonpatch --quiet

# ==========================================
# 2. EXECUÇÃO DO PLAYBOOK GARANTINDO O CONTEXTO
# ==========================================
echo "🚀 Disparando o Playbook de Deploy da Aplicação..."

# Mudamos temporariamente para a pasta ansible para que ele herde o ansible.cfg automaticamente
cd ansible
ansible-playbook playbooks/01_deploy_apps.yml
cd ..

echo "✅ [Ansible Setup] Execução concluída com sucesso!"
