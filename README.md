# Ultraseven Kubernetes Cluster (Local via Terraform & Kind)

Este projeto automatiza a criação e destruição de um cluster Kubernetes local utilizando **Terraform** e **Kind (Kubernetes in Docker)** dentro do ambiente **WSL (Ubuntu Linux)**. A esteira já vem configurada para subir o cluster, aplicar definições de base (como banco de dados Postgres, Secrets e ConfigMaps) e abrir automaticamente a interface visual do **K9s**.

---

## 🏗️ Arquitetura do Ambiente

* **Orquestrador de Infraestrutura:** Terraform (v1.0.0+)
* **Provedor Kubernetes Local:** Kind (Nós rodando como containers Docker)
* **Gerenciador de Cluster:** K9s (Interface de terminal)
* **Componentes de Base:** Configurações automatizadas na pasta `./settings` (Postgres, ConfigMaps, etc.)

---

## 🛠️ Pré-requisitos (WSL / Ubuntu)

Antes de rodar a automação, certifique-se de ter as seguintes ferramentas instaladas no seu WSL:

1. **Docker:** Instale o Docker nativo ou ative a integração do *Docker Desktop do Windows* com a sua distribuição Linux em: `Settings -> Resources -> WSL integration`.
2. **Terraform:** Instalado e configurado no seu `$PATH`.
3. **K9s:** Instalado no sistema para visualização automatizada dos recursos.

---

## 📁 Estrutura do Projeto

```text
ultraseven-k8s-cluster/
├── .kube/                  # Gerado automaticamente (Ignorado no Git)
├── settings/               # Seus manifestos Kubernetes de base
│   ├── config.yaml
│   ├── secrets.yaml
│   └── postgres-full.yaml
├── bootstrap.sh            # Script para subir tudo (Automação total)
├── destroy.sh              # Script para limpar tudo do zero
├── main.tf                 # Recursos do Terraform (Kind e Manifests)
├── providers.tf            # Configuração dos Provedores (Kind, Kubectl, Null)
├── outputs.tf              # Mensagens de sucesso pós-instalação
└── .gitignore              # Proteção para não vazar credenciais ou estados
```

---

## 🚀 Como Utilizar

Toda a complexidade de comandos do Terraform (`init`, `apply`, `destroy`, `lock files`) foi encapsulada nos scripts Bash para garantir automação total.

### 1. Subindo o Cluster (Bootstrap)

Para provisionar o cluster, configurar as permissões do Docker, injetar as configurações da pasta `./settings` e abrir o K9s, execute:

```bash
# Dê permissão de execução na primeira vez
chmod +x bootstrap.sh

# Execute o bootstrap
./bootstrap.sh
```

**O que o script faz sozinho:**
* Ajusta permissões do socket do Docker no WSL se necessário.
* Limpa caches antigos e força o `terraform init -upgrade`.
* Cria o cluster `ultraseven-cluster`.
* Copia o arquivo `kubeconfig` gerado para o diretório padrão global do seu sistema (`~/.kube/config`).
* Aplica os arquivos YAML com suporte a múltiplos recursos internos (separados por `---`).
* Abre o **K9s** automaticamente no contexto do novo cluster.

### 2. Destruindo o Cluster (Clean Up)

Quando terminar de desenvolver e quiser liberar memória RAM e recursos do seu computador de forma limpa, execute:

```bash
# Dê permissão de execução na primeira vez
chmod +x destroy.sh

# Execute a destruição
./destroy.sh
```

**O que o script faz sozinho:**
* Executa o `terraform destroy` de forma silenciosa e sem pedir confirmação.
* Desliga e apaga completamente os containers do Kind do Docker.
* Remove os arquivos `kubeconfig` temporários e órfãos do seu sistema.

---

## 🔒 Segurança (Git)

O projeto já inclui um arquivo `.gitignore` configurado. **Nunca remova as travas do git**, pois o arquivo `terraform.tfstate` armazena de forma aberta senhas do Postgres, chaves e Secrets criados pelo Kubernetes que não devem ser enviados para repositórios públicos.

