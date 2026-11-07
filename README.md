# Ultraseven Kubernetes Cluster (Local via Terraform & Kind)

Este projeto automatiza a criação e destruição de um cluster Kubernetes local utilizando **Terraform** e **Kind (Kubernetes in Docker)** dentro do ambiente **WSL (Ubuntu Linux)**. A esteira integra o provisionamento de infraestrutura com o gerenciamento de configuração do **Ansible** para subir o cluster e aplicar as definições de base.

O controle do ecossistema é centralizado por um **Makefile**, fornecendo uma interface de linha de comando padronizada e simplificada para os participantes do treinamento.

---

## 🏗️ Arquitetura do Ambiente

* **Central de Controle:** Makefile (Centralização de comandos do laboratório)
* **Orquestrador de Infraestrutura:** Terraform (v1.0.0+)
* **Gerenciador de Configuração:** Ansible (Automação de deploy de apps e Ops Dia 2)
* **Provedor Kubernetes Local:** Kind (Nós rodando como containers Docker)
* **Gerenciador de Cluster:** K9s (Interface visual de terminal acessada manualmente)
* **Componentes de Base:** Configurações automatizadas na pasta `./settings` (Postgres, ConfigMaps, etc.)

---

## 🛠️ Pré-requisitos (WSL / Ubuntu)

Antes de rodar a automação, certifique-se de ter as seguintes ferramentas instaladas no seu WSL:

1. **Docker:** Instale o Docker nativo ou ative a integração do *Docker Desktop do Windows* com a sua distribuição Linux em: `Settings -> Resources -> WSL integration`.
2. **Terraform:** Instale o binário do Terraform e garanta que ele esteja configurado no seu `$PATH`.
3. **Make:** Utilitário do sistema para execução dos comandos unificados (`sudo apt install make`).
4. **K9s:** Ferramenta visual de gerenciamento. Para instalar direto pelo terminal do seu WSL (Ubuntu), vide o documento KUBECTL_BASIC_COMMANDS.md

---

## 📁 Estrutura do Projeto

```text
ultraseven-k8s-cluster/
├── .kube/                  # Gerado automaticamente (Ignorado no Git)
├── settings/               # Seus manifestos Kubernetes de base
│   ├── config.yaml
│   ├── secrets.yaml
│   └── postgres-full.yaml
├── ansible/                # Laboratório de Automação com Ansible
│   ├── ansible.cfg        # Configurações do Ansible (Callback visual, desativação de SSH, etc.)
│   ├── inventory.ini      # Aponta para o localhost (Conexão local via API do K8s)
│   ├── playbooks/
│   │   ├── 01_deploy_apps.yml # Playbook de Deploy automatizado dos manifestos de base
│   │   └── 02_cluster_ops.yml # Playbook de Troubleshooting (Auditoria e dump de logs de erro)
│   └── roles/             # Estrutura para boas práticas de reaproveitamento de código
├── Makefile                # Central unificada de comandos do laboratório (Central Engine)
├── bootstrap.sh            # Script de provisionamento e integração das ferramentas
├── ansible-setup.sh        # Script wrapper (Valida pré-requisitos, instala o Ansible e roda o deploy)
├── destroy.sh              # Script de limpeza total do ambiente
├── locals.tf               # Referências de arquivos e pastas do Terraform
├── main.tf                 # Recursos do Terraform (Kind e ciclo de vida)
├── providers.tf            # Configuração dos Provedores (Kind, Kubectl, Null)
├── outputs.tf              # Mensagens visuais de sucesso pós-instalação do Terraform
├── variables.tf            # Declaração de variáveis do Terraform
└── .gitignore              # Proteção para não vazar estados, credenciais ou logs locais
```

---

## 🚀 Como Utilizar

Toda a complexidade de comandos e chamadas de scripts foi envelopada no **Makefile**. Você não precisa navegar por pastas ou rodar scripts individuais manualmente.

### 1. Menu de Ajuda

Para listar todos os comandos disponíveis no treinamento e suas respectivas descrições, basta digitar na raiz do projeto:

```bash
make
```

### 2. Subindo o Cluster e as Aplicações

Para provisionar o cluster Kind através do Terraform, configurar as credenciais do sistema e instalar/executar o Ansible em background para a entrega dos manifestos de base, execute:

```bash
make up
```

**O que a esteira faz de forma automatizada:**
* Ajusta de forma transparente as permissões do socket do Docker no WSL.
* Inicializa o Terraform, atualiza os provedores locais e cria o cluster Kubernetes.
* Unifica o arquivo `kubeconfig` gerado e o exporta globalmente para o sistema.
* Dispara o script wrapper para verificar e instalar o Ansible, suas coleções do Galaxy e módulos Python automaticamente.
* Executa o playbook do Ansible para implantar de forma agnóstica as configurações e o banco de dados.
* Exibe o resumo detalhado da execução e o sucesso das tarefas diretamente no seu terminal, deixando o ambiente pronto para validação.

*Após o término do script, digite `k9s` no seu terminal para abrir a interface visual de gerenciamento.*

### 3. Diagnóstico e Auditoria (Operações de Dia 2)

Caso queira rodar rotinas de administração de cluster para verificar a saúde dos recursos, monitorar pods instáveis e extrair logs de erro de dentro dos containers automaticamente para uma pasta local de dumps, execute:

```bash
make status
```

### 4. Destruindo o Cluster (Clean Up)

Quando terminar as atividades de desenvolvimento e quiser liberar completamente a memória RAM e os recursos do computador, execute:

```bash
make down
```

**O que o comando faz sozinho:**
* Executa o `terraform destroy` de forma silenciosa e sem pedir confirmação, removendo o cluster Kind.
* Apaga e limpa os containers e nós do Docker.
* Remove os arquivos `kubeconfig` temporários locais e do sistema.
* Elimina pastas residuais de relatórios de erros (`troubleshooting_dump`) geradas durante os laboratórios.

---

## 🔒 Segurança (Git)

O projeto já inclui um arquivo `.gitignore` blindado para o ecossistema Terraform e Ansible. 

**Nunca remova as travas do git.** O arquivo `terraform.tfstate` armazena senhas e segredos em texto claro, e a pasta `troubleshooting_dump` pode conter logs com informações sensíveis da aplicação. Ambos estão protegidos para evitar vazamentos acidentais para repositórios públicos.
