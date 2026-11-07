# ==============================================================================
# 🚀 ULTRASEVEN KUBERNETES CLUSTER - AUTOMATION ENGINE
# ==============================================================================

.PHONY: up down status plan clear help

# Comando padrão caso o usuário digite apenas 'make'
.DEFAULT_GOAL := help

help: ## 📋 Exibe as opções de comandos disponíveis no treinamento
	@echo "Opções de comandos para o laboratório DevOps:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## 🏗️  Provisiona a infraestrutura (Terraform) e roda as automações (Ansible)
	@echo "🏁 [Makefile] Iniciando esteira completa..."
	@chmod +x bootstrap.sh ansible-setup.sh
	@./bootstrap.sh

down: ## 🗑️  Destrói completamente o cluster e limpa arquivos locais
	@echo "🔥 [Makefile] Iniciando destruição e limpeza completa..."
	@chmod +x destroy.sh
	@./destroy.sh

status: ## 🔍 Executa o Playbook de diagnóstico de Dia 2 (Troubleshooting)
	@echo "🛠️ [Makefile] Rodando auditoria de integridade do cluster..."
	@if [ ! -f ".kube/config" ]; then \
		echo "❌ Erro: O arquivo .kube/config não foi encontrado!"; \
		echo "👉 O cluster está desligado. Execute 'make up' primeiro para iniciar o ambiente."; \
		exit 1; \
	fi
	@cd ansible && ansible-playbook playbooks/02_cluster_ops.yml

plan: ## 📋 Executa apenas o planejamento do Terraform para validação
	@echo "🔍 [Makefile] Validando plano do Terraform..."
	@terraform plan
