# ☸️ Guia de Comandos: Cluster Kubernetes (Kind) no WSL

Este guia contém os comandos essenciais utilizados para configurar, gerenciar e testar o cluster local **ultraseven-cluster**.

---

## 📥 Instalação de Ferramentas (WSL/Ubuntu)

### Instalar K9s (Interface Visual)
> Método recomendado via pacote Debian para evitar erros de download HTML.

```bash
# 1. Baixar o pacote oficial (.deb)
wget https://github.com

# 2. Instalar o pacote
sudo apt install ./k9s_linux_amd64.deb

# 3. Remover o instalador após o sucesso
rm k9s_linux_amd64.deb

# 4. Testar a instalação
k9s
```

### Instalar Kind (Kubernetes in Docker)
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```
---


## 🛠️ Gerenciamento do Cluster (Kind)

- **Criar o cluster:**
```bash
  kind create cluster --name ultraseven-cluster
```
- **Listar clusters ativos:**
```bash
  kind get clusters
```
- **Definir foco no cluster (Contexto):**
```bash
  kubectl config use-context kind-ultraseven-cluster
```
- **Excluir o cluster:**
```bash
  kind delete cluster --name ultraseven-cluster
```

---

## 📦 Gerenciamento de Cargas (Deployments e Pods)

- **Criar um Deployment com réplicas:**
```bash
  kubectl create deployment nginx-ultraseven --image=nginx --replicas=3
```
- **Alterar o número de réplicas (Scale):**
```bash
  kubectl scale deployment nginx-ultraseven --replicas=5
```
- **Listar todos os Pods:**
```bash
  kubectl get pods
```
- **Ver Pods de todos os Namespaces (Sistema):**
```bash
  kubectl get pods -A
```

---

## 🌐 Rede e Acesso (Services)

- **Expor Deployment como um Serviço interno:**
```bash
  kubectl expose deployment nginx-ultraseven --port=80 --target-port=80 --name=ultraseven-service
```
- **Acessar pelo navegador do Windows (Port-Forward):**
```bash
  # Acessível em http://localhost:9090
  kubectl port-forward svc/ultraseven-service 9090:80
```
- **Listar Serviços ativos:**
```bash
  kubectl get svc
```

---

## 🔍 Inspeção e Debug

- **Abrir interface visual no terminal:**
```bash
  k9s
```
- **Ver detalhes técnicos de um recurso:**
```bash
  kubectl describe pod <nome-do-pod>
```
- **Ver logs de um Pod:**
```bash
  kubectl logs -f <nome-do-pod>
```
- **Entrar no terminal dentro do Container:**
```bash
  kubectl exec -it <nome-do-pod> -- bash
```

---

## Iniciando e Parando o Cluster

- **Parando:**
```bash
  docker stop ultraseven-cluster-control-plane
```
  
- **Iniciando:**
```bash
  docker start ultraseven-cluster-control-plane
```

---

## Deploy de Uma App Java

### dockerfile

Estágio de Build (Usa Maven com OpenJDK para compilar)

```bash
# Estágio de Compilação
FROM ubuntu:24.04 AS build
WORKDIR /app

RUN apt-get update && apt-get install -y \
    openjdk-21-jdk-headless \
    maven \
    && rm -rf /var/lib/apt/lists/*

COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Estágio de Execução (Otimizado para Quarkus)
FROM ubuntu:24.04
WORKDIR /app

RUN apt-get update && apt-get install -y \
    openjdk-21-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# O Quarkus precisa de toda a pasta quarkus-app para funcionar corretamente
COPY --from=build /app/target/quarkus-app/lib/ /app/lib/
COPY --from=build /app/target/quarkus-app/*.jar /app/
COPY --from=build /app/target/quarkus-app/app/ /app/app/
COPY --from=build /app/target/quarkus-app/quarkus/ /app/quarkus/

EXPOSE 8080
# O ponto de entrada padrão do Quarkus é o quarkus-run.jar
ENTRYPOINT ["java", "-jar", "quarkus-run.jar"]
```
  
### ☕ Deploy de Projeto Java (OpenJDK)

1. **Gerar a imagem Docker:**
 ```bash
   docker build -t java-app-ultraseven:v1 .
 ```

2. **Carregar a imagem para dentro do Kind:**
   *(Obrigatório para o cluster enxergar a imagem local)*
 ```bash
   kind load docker-image java-app-ultraseven:v1 --name ultraseven-cluster
 ```

3. **Criar o Deployment e o Serviço:**
 ```bash
   # Criar o deploy
   kubectl create deployment java-app --image=java-app-ultraseven:v1
   
   # Escalar para 3 réplicas
   kubectl scale deployment java-app --replicas=3
   
   # Expor porta
   kubectl expose deployment java-app --port=8080 --target-port=8080 --name=java-service
 ```

4. **Acessar no Windows:**
 ```bash
   kubectl port-forward svc/java-service 8080:8080
 ```

---

### Configurando env vars via linha de comando e via deployment.yaml

Para gerenciar variáveis de ambiente (Env Vars) no Kubernetes, usamos dois objetos principais: ConfigMaps (para dados abertos, como URLs) e Secrets (para dados sensíveis, como senhas).

Isso evita que você exponha senhas no seu Dockerfile ou no histórico do terminal.

#### Criando um ConfigMap (Configurações Gerais)

Vamos supor que seu app Java precise de um perfil (Spring Profile) e uma URL de API.

 ```bash
kubectl create configmap java-config \
  --from-literal=SPRING_PROFILES_ACTIVE=prod \
  --from-literal=API_URL=https://ultraseven.com
 ```

#### Criando um Secret (Dados Sensíveis)   

Para senhas de banco de dados ou chaves de API. O Kubernetes criptografa esses dados em base64.

 ```bash
kubectl create secret generic java-db-secret \
  --from-literal=DB_PASSWORD=senha_super_secreta_123 \
  --from-literal=DB_USERNAME=admin
 ```   
 

### Utilizando deployment.yaml

Para gerenciar variáveis de ambiente (Env Vars) no Kubernetes, usamos dois objetos principais: ConfigMaps (para dados abertos, como URLs) e Secrets (para dados sensíveis, como senhas).

Isso evita que você exponha senhas no seu Dockerfile ou no histórico do terminal. 

 ```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: java-app
  template:
    metadata:
      labels:
        app: java-app
    spec:
      containers:
      - name: java-container
        image: java-app-ultraseven:v1
        ports:
        - containerPort: 8080
        env:
          # Pegando valor direto do ConfigMap
          - name: APP_PROFILE
            valueFrom:
              configMapKeyRef:
                name: java-config
                key: SPRING_PROFILES_ACTIVE
          # Pegando valor direto do Secret
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: java-db-secret
                key: DB_PASSWORD
 ```
   
#### Como aplicar e verificar

No console, digite:

 ```bash
kubectl apply -f deployment.yaml
 ```   

Verifique se as variáveis subiram:
   
 ```bash
kubectl exec -it <nome-do-pod> -- env
 ```   
   
No K9s, selecione o Pod, aperte e (edit) ou procure a seção Environment nos detalhes do Pod.

---

### 🐘 Banco de Dados (PostgreSQL)

- **Acessar os nodes existentes:**
```bash
kubectl get nodes -o wide
```

- **Acessar os pods existentes:**
```bash
kubectl get pods
```

- **Acessar os pods existentes:**
```bash
kubectl exec -it deployment/postgres-db -- printenv
```

- **Acessar o terminal do banco (psql):**
```bash
  kubectl exec -it deployment/postgres-db -- psql -U postgres
```

- **Acessar o banco pelo Windows (DBeaver/IntelliJ):**
```bash
  # Agora você pode conectar no localhost:5432 do Windows
  kubectl port-forward pod/postgres-db 5432:5432
```
  
#### Criar o Pedido de Espaço

Criar o Pedido de Espaço

```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi  # Reserva 1 Gigabyte para o banco
```
    
#### Criar o Postgres usando o Volume

Como agora precisamos de uma configuração mais complexa, o ideal é usar um arquivo postgres-deployment.yaml. 

Ele vai montar o volume na pasta onde o Postgres guarda os dados (/var/lib/postgresql/data).

Crie o arquivo postgres-deployment.yaml:

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
spec:
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```
  
#### 💾 Persistência de Dados (Volumes)

- **Verificar se o volume foi criado:**
```bash
  kubectl get pvc
```

- **Aplicar configuração de volume e banco:**
```bash
  kubectl apply -f postgres-pvc.yaml
  kubectl apply -f postgres-deployment.yaml
```

#### Serviço Fixo para o Banco de Dados

Aqui está o YAML do Service. Ele funciona como um "nome fixo" (DNS) dentro do cluster. 

Assim, seu código Java sempre apontará para postgres-service, não importa se o Pod do banco reiniciou ou mudou de endereço IP.

Crie um arquivo chamado postgres-service.yaml:

```bash
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres       # Deve ser igual ao label definido no Deployment
  ports:
    - protocol: TCP
      port: 5432        # Porta que o Service expõe para o cluster
      targetPort: 5432  # Porta real onde o container do Postgres escuta
  type: ClusterIP       # Tipo padrão para comunicação interna entre Pods
```
  
#### Como utilizar no seu Projeto Java

Com este Service aplicado, a sua String de Conexão (JDBC) no IntelliJ deve ficar exatamente assim:
 
```bash
jdbc:postgresql://postgres-service:5432/postgres 
```
  
#### 🔌 Redes: Serviço de Banco de Dados

- **Aplicar o serviço do banco:**
```bash
  kubectl apply -f postgres-service.yaml
```

- **Verificar se o DNS interno está resolvendo:**
  *(Rode este comando de dentro de qualquer outro Pod)*
```bash
  kubectl exec -it <nome-do-seu-pod-java> -- nslookup postgres-service
```
  
#### PVC, Service e Deployment Juntos

Aqui está o arquivo postgres-full.yaml unificado, contendo o PVC, Service e Deployment, que pode ser aplicado de uma só vez para facilitar o gerenciamento no Kubernetes. 

O arquivo configura o banco de dados Postgres com armazenamento persistente e senha protegida por segredo.

```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  type: NodePort       # ClusterIP para NodePort
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432        # Porta interna do cluster
      targetPort: 5432  # Porta no container
      nodePort: 30432   # Porta exposta para o "mundo externo" (Windows/IDE)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        args: ["-c", "shared_buffers=128MB", "-c", "max_connections=100"]
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: SPRING_DATASOURCE_PASSWORD
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```
  
#### Como aplicar

1. Crie o segredo:
```bash
kubectl create secret generic postgres-secret --from-literal=password=password
```
2. Para aplicar o arquivo full, utilize:
```bash
kubectl apply -f postgres-full.yaml
```
  
#### Como eu testo o serviço do Postgres?

Para testar se o seu PostgreSQL está funcionando no Kubernetes, você deve verificar o status dos recursos e depois realizar um teste de conexão interna ou externa

- Verifique os Recursos no Cluster

Antes de conectar, certifique-se de que o Pod e o Serviço estão rodando sem erros

- Verifique se o Pod está com o status 'Running'

```bash
kubectl get pods -l app=postgres
```

- Verifique se o serviço mapeou a porta corretamente

```bash
kubectl get service postgres-service
```

- Veja os logs do banco de dados para checar se ele iniciou com sucesso

```bash
kubectl logs -l app=postgres
```
  
Teste de Conexão Interna (Direto no Cluster)Você pode interagir diretamente com o banco criando um terminal temporário dentro do próprio container do PostgreSQL.bash# 

Entrar no terminal do container (substitua pelo nome real do seu Pod)

```bash
kubectl exec -it deployment/postgres-db -- psql -U postgres
```
  
Teste de Conexão Externa (Sua Máquina / IDE)

Como você configurou o serviço como NodePort na porta 30432, você pode conectar usando ferramentas como DBeaver, pgAdmin ou o terminal da sua máquina local.Host: localhost (se usar Minikube/Docker Desktop) ou o IP de um nó do cluster.

```bash
Porta: 30432
Usuário: postgres
Senha: A senha definida na secret app-secrets sob a chave SPRING_DATASOURCE_PASSWORD.
```

Se estiver usando o Minikube e o localhost não funcionar, descubra o IP correto do nó com o comando:

```bash
minikube service postgres-service --url
```
  
#### Comandos de Verificação do Sistema Postgres (psql)

-Listar todos os bancos de dados: 

```sql 
  \l
```

-Listar todas as tabelas do banco atual: 

```sql 
  \dt
```
  
-Verificar os usuários (roles) criados e suas permissões: 

```sql 
  \du
```
  
-Conectar a um banco de dados específico: 

```sql 
  \c nome_do_banco
```
  
-Sair do terminal do Postgres: 

```sql 
  \q
```

### 💡 Dica de "Mestre" do Kubernetes

Sempre que você criar um Deployment e um Service, certifique-se de que o campo selector do Service bate exatamente com as labels do template do Deployment. 

É assim que o Kubernetes sabe para qual "caixa" enviar o tráfego.

## Criar Configurações Separadas (Estilo Corporativo)

Os projetos devem ser separados em 3 partes:

1. Projeto Java: Dockerfile e app-deployment.yaml

O Dockerfile já foi mencionado acima. Vamos para o app-deployment.yaml:

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: titanic-lifeguard
  labels:
    app: titanic-lifeguard
spec:
  replicas: 1
  selector:
    matchLabels:
      app: titanic-lifeguard
  template:
    metadata:
      labels:
        app: titanic-lifeguard
    spec:
      containers:
        - name: java-container
          image: titanic-lifeguard:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
          env:
            - name: JAVA_OPTS
              value: "-Xms64m -Xmx128m -XX:MaxRAMPercentage=50.0"

          # 1. Variáveis de Ambiente
          envFrom:
            - configMapRef:
                name: app-config
            - secretRef:
                name: app-secrets

          # 2. Verificação de Saúde (Liveness)
          livenessProbe:
            httpGet:
              path: /q/health/live
              port: 8080
            initialDelaySeconds: 45
            periodSeconds: 15
            timeoutSeconds: 3
            failureThreshold: 3

          # 3. Verificação de Prontidão (Readiness)
          readinessProbe:
            httpGet:
              path: /q/health/ready
              port: 8080
            initialDelaySeconds: 20
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3

          # 4. Alocação de Recursos (Corrigido de Tabs para Espaços)
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: titanic-lifeguard
spec:
  type: NodePort
  selector:
    app: titanic-lifeguard # Garanta que essa label seja idêntica à do seu Pod
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
      nodePort: 30080 # Esta porta liga o Service ao 'containerPort' do Kind

```

2. Infra do Banco de Dados: postgres-full.yaml

```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  type: NodePort       # ClusterIP para NodePort
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432        # Porta interna do cluster
      targetPort: 5432  # Porta no container
      nodePort: 30432   # Porta exposta para o "mundo externo" (Windows/IDE)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        args: ["-c", "shared_buffers=128MB", "-c", "max_connections=100"]
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: SPRING_DATASOURCE_PASSWORD
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```
  
⚠️ Importante: Ajuste no Kind (O "Pulo do Gato")

Para que o NodePort funcione no Kind (WSL), o Kind precisa saber que deve mapear a porta do container do Docker para o seu Windows. 

Se você criou o cluster com o comando simples kind create cluster, o NodePort pode não responder no localhost.

Se não funcionar direto, você tem duas opções:A forma rápida: Use o kubectl port-forward svc/postgres-service 5432:5432. 

É mais garantido em clusters Kind que já estão rodando.

A forma definitiva: Recriar o cluster com um arquivo de configuração (kind-config.yaml) que mapeia as portas:

```bash
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ultraseven-cluster # Define o nome aqui também
nodes:
- role: control-plane
  extraPortMappings:
  # Mapeamento para o seu App Java
  - containerPort: 30080 
    hostPort: 8080
    listenAddress: "0.0.0.0" # Permite acesso pelo Windows
  # Mapeamento para o Banco de Dados (Postgres)
  - containerPort: 30432
    hostPort: 5432
    listenAddress: "0.0.0.0"
---
apiVersion: v1
kind: Service
metadata:
  name: titanic-lifeguard
spec:
  type: NodePort
  selector:
    app: titanic-lifeguard # Garanta que essa label seja idêntica à do seu Pod
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
      nodePort: 30080 # Esta porta liga o Service ao 'containerPort' do Kind
```

3. Variáveis de Ambiene (Env Vars): config.yaml e secrets.yaml

3.1. config.yaml
```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # Spring Boot entende essas envs automaticamente
  SPRING_PROFILES_ACTIVE: "prod"
  SPRING_DATASOURCE_URL: "jdbc:postgresql://postgres-service:5432/postgres"
  SPRING_DATASOURCE_USERNAME: "postgres"
  # Configurações de JVM
  JAVA_TOOL_OPTIONS: "-Xms256m -Xmx512m"

```

3.2. secrets.yaml
```bash
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # 'ultraseven123' convertido para base64
  SPRING_DATASOURCE_PASSWORD: dWx0cmFtYW4xMjM=

```

#### 📂 Organização do Projeto

- **Configuração (ConfigMaps/Secrets):** Define as Env Vars no cluster.
- **Código Java (Docker Image):** Contém apenas o JRE e o arquivo .jar.
- **Infra (Postgres/Volumes):** Mantém o banco de dados independente da App.

#### 🚀 Checklist de Deploy (Ordem Correta)

1. Crie as Env Vars primeiro: `kubectl apply -f projeto-env/` (Para que o Segredo da senha exista quando o banco subir).
2. Suba o Banco: `kubectl apply -f projeto-db/postgres-full.yaml`
3. Suba o Java: `kubectl apply -f projeto-java/app-deployment.yaml`

### 🔍 Como conferir tudo no K9s:

- Aperte :pvc para ver se o disco do banco está Bound (conectado).
- Aperte :svc para ver se o postgres-service e o java-service estão na lista.
- Aperte :pods e veja se ambos estão verdes.

### Automatizando o Deploy via Shell Script

Antes de tudo, instale o Maven (se nao estiver instalado) no WSL:

```bash
  sudo apt update
  sudo apt install maven
```
  
Ao terminar, verifique se esta instalado e qual versao:

```bash
mvn -version
```

A estrutura de pastas que deve ser utilizada para isolar a infra do cluster e o projeto Java deve ser assim:

```bash
/ (pasta raiz do seu workspace)
├── infra-cluster/          
│   ├── deploy-script.sh
│   ├── kind-config.yaml
│   └── settings/          
│        ├── config.yaml
│        ├── secrets.yaml
│        └── postgres-full.yaml
└── nome-do-seu-projeto/   
    ├── pom.xml
    ├── Dockerfile
    ├── app-deployment.yaml
    └── src/

```

1. Crie o arquivo deploy.sh no wsl

```bash
#!/bin/bash

# ==============================================================================
# CONFIGURAÇÕES DO PROJETO (Ajuste apenas estas duas se necessário)
# ==============================================================================
# Nome da pasta do projeto Java que está ao lado da 'infra-cluster'
PROJECT_FOLDER_NAME=$(ls -d ../*/ | grep -v "infra-cluster" | head -n 1 | xargs basename)

# Nome que você quer dar ao cluster Kind
CLUSTER_NAME="ultraseven-cluster"
# ==============================================================================

# caminhos Relativos
INFRA_DIR="./settings"
KIND_CONFIG="./kind-config.yaml"
APP_DIR="../$PROJECT_FOLDER_NAME"

# Variáveis automáticas
# Extrai o nome do artefato do pom.xml ou usa o nome da pasta como fallback
IMAGE_NAME=$(echo "$PROJECT_FOLDER_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'):latest

echo "🚀 Iniciando Deploy Universal"
echo "📂 Projeto Detectado: $PROJECT_FOLDER_NAME"
echo "🐳 Imagem: $IMAGE_NAME"

# 0. Verificar se a pasta do projeto existe
if [ ! -d "$APP_DIR" ]; then
    echo "❌ ERRO: A pasta '$PROJECT_FOLDER_NAME' não foi encontrada em $APP_DIR"
    exit 1
fi

# 1. Garantir que o Cluster Kind existe
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "☸️ Cluster '$CLUSTER_NAME' já ativo."
else
    echo "🏗️ Criando cluster '$CLUSTER_NAME'..."
    kind create cluster --config "$KIND_CONFIG" || exit 1
fi

# 2. Build Java (Maven)
echo "📦 Compilando projeto Java..."
(cd "$APP_DIR" && mvn clean package -DskipTests) || { echo "❌ Erro no Maven!"; exit 1; }

# 3. Build Docker
echo "🐳 Gerando imagem Docker..."
docker build -t "$IMAGE_NAME" "$APP_DIR" || { echo "❌ Erro no Docker Build!"; exit 1; }

# 4. Enviar para o Kind
echo "🚚 Carregando imagem no cluster..."
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

# 5. Aplicar Manifestos K8s
echo "📂 Aplicando configurações..."
# Aplica Configs/Secrets/Banco
kubectl apply -f "$INFRA_DIR/"

# Aplica os YAMLs da pasta do projeto (Deployment/Service)
# Procura por qualquer arquivo .yaml ou .yml na raiz do projeto
kubectl apply -f "$APP_DIR/" --selector='!heritage=helm' --prune=false 2>/dev/null || \
kubectl apply -f "$APP_DIR/app-deployment.yaml"

# 6. Refresh dos Pods
# Tenta reiniciar o deployment baseado no label 'app' para garantir que pegou a imagem nova
echo "🔄 Reiniciando pods..."
kubectl rollout restart deployment -l "app=$PROJECT_FOLDER_NAME" 2>/dev/null || \
kubectl rollout restart deployment $(kubectl get deployments -o jsonpath='{.items[0].metadata.name}')

# 7. Limpeza
echo "🧹 Limpando arquivos temporários..."
rm -rf "$APP_DIR/target"
docker image prune -f

echo "✅ PROCESSO CONCLUÍDO!"
echo "✅ Verifique o status no K9s."

```

2. Dê permissão de execução:

```bash
cd infra-cluster
chmod +x deploy-script.sh
./deploy-script.sh
```

3. Execute o arquivo (Sempre que mudar o código Java ou a infra, basta rodar):

```bash
./deploy-script.sh
```

### ☸️ Cluster Infra: Automação Kubernetes (Kind)

Este repositório contém a infraestrutura e os scripts necessários para subir um ambiente local de desenvolvimento utilizando **Kubernetes (Kind)**, **Docker** e **Java**.

---

#### 📂 Estrutura de Pastas Esperada

Para que a automação funcione corretamente, o script espera que a pasta da infraestrutura e a pasta do projeto Java estejam no mesmo nível hierárquico:

```text
/workspace
├── infra-cluster/           <-- (Você está aqui)
│   ├── deploy-script.sh     <-- Script de automação
│   ├── kind-config.yaml     <-- Configuração de portas do Kind
│   └── settings/            <-- YAMLs de ConfigMaps, Secrets e Banco
│        ├── config.yaml
│        ├── secrets.yaml
│        └── postgres-full.yaml
└── nome-do-seu-projeto/     <-- Seu projeto Java
    ├── pom.xml
    ├── Dockerfile
    └── .deployment/app-deployment.yaml
```

---

#### 🚀 Como usar em um novo projeto

1. **Copie** a pasta `infra-cluster` para a raiz do seu workspace (ao lado da pasta do seu projeto Java).
2. **Edite** o arquivo `deploy-script.sh` e atualize o nome da pasta do projeto:
 ```bash
   PROJECT_FOLDER_NAME="nome-do-seu-projeto"
 ```
3. **Verifique os YAMLs** na pasta `settings/` para garantir que as credenciais e URLs de banco de dados estão corretas para o novo contexto.
4. **Execute o deploy** via terminal (WSL/Linux):
 ```bash
   cd infra-cluster
   chmod +x deploy-script.sh
   ./deploy-script.sh
 ```

---

#### 🛠️ O que o script automatiza?

*   **Gestão do Cluster:** Cria o cluster Kind automaticamente caso ele não exista, usando o `kind-config.yaml`.
*   **Compilação Java:** Executa `mvn clean package` dentro da pasta do projeto vizinha.
*   **Containerização:** Faz o build da imagem Docker localmente.
*   **Sincronização:** Carrega a imagem para dentro dos nós do Kind (não precisa de Docker Hub).
*   **Orquestração:** Aplica todos os manifestos da pasta `settings/` e do projeto Java.
*   **Hot Refresh:** Reinicia o Deployment para garantir que a versão mais nova do código entre em execução.
*   **Limpeza Automática:** Remove a pasta `target` e imagens Docker órfãs (prune) após o sucesso, economizando espaço no disco do WSL.

---

#### 🌐 Acessos Rápidos (Default)

Após a execução, os serviços estarão mapeados conforme o `kind-config.yaml`:

-   **Aplicação Java:** [http://localhost:8080](http://localhost:8080)
-   **PostgreSQL:** `localhost:5432` (Acesso via DBeaver, IntelliJ ou pgAdmin)

---

#### 📋 Pré-requisitos

*   **Docker** (WSL2)
*   **Kind** e **Kubectl** instalados.
*   **Maven** configurado no PATH.
*   **K9s** (Recomendado para visualização do cluster).

---

## Que tal um script Bootstrap Só para a Infra?

Este script ignora o Java e foca em deixar o ecossistema pronto.

 ```bash
#!/bin/bash

# --- Configurações ---
CLUSTER_NAME="ultraseven-cluster"
KIND_CONFIG="./kind-config.yaml"
SETTINGS_DIR="./settings"

echo "🏗️  Iniciando Bootstrap da Infraestrutura..."

# 1. Criar Cluster se não existir
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "☸️  Cluster '$CLUSTER_NAME' já está ativo. Atualizando configurações..."
else
    echo "🚀 Criando cluster '$CLUSTER_NAME' do zero..."
    kind create cluster --config "$KIND_CONFIG" || { echo "❌ Erro ao criar cluster"; exit 1; }
fi

# 2. Aplicar Configurações de Base (ConfigMaps, Secrets, Banco)
echo "📂 Aplicando definições em $SETTINGS_DIR..."

if [ -d "$SETTINGS_DIR" ]; then
    kubectl apply -f "$SETTINGS_DIR/"
else
    echo "⚠️  Pasta $SETTINGS_DIR não encontrada! Verifique seus arquivos YAML."
    exit 1
fi

# 3. Aguardar o Banco de Dados (Opcional, mas recomendado)
echo "🐘 Aguardando o Postgres ficar pronto (isso pode levar alguns segundos)..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s 2>/dev/null

echo "✅ BOOTSTRAP CONCLUÍDO!"
echo "--------------------------------------------------"
echo "🌐 Cluster: $CLUSTER_NAME"
echo "🔌 Banco: localhost:5432"
echo "✅ Verifique o status no K9s."
echo "🛠️  Próximo passo: Rodar o script de deploy da sua aplicação Java."
echo "--------------------------------------------------"
 ```
   
## Agora Deployment Desacoplado!

 ```bash
#!/bin/bash

# ==============================================================================
# SCRIPT DE DEPLOY UNIVERSAL - FOCO EM APLICAÇÃO
# ==============================================================================
# Uso: ./deploy-script.sh [CAMINHO_DO_PROJETO]
# Ex:  ./deploy-script.sh ../projeto-java
# ==============================================================================

# --- Configurações de Contexto ---
CLUSTER_NAME="ultraseven-cluster"

# 1. Define o caminho do projeto (Argumento $1 ou padrão relativo)
APP_DIR="${1:-../nome-do-seu-projeto/.deployment}"

# 2. Validação de existência da pasta da aplicação
if [ ! -d "$APP_DIR" ]; then
    echo "❌ ERRO: Diretório da aplicação não encontrado em: $APP_DIR"
    echo "Uso: $0 [caminho_do_projeto]"
    exit 1
fi

# 3. Detecta o nome do projeto baseado na pasta para nomear a imagem
PROJECT_NAME=$(basename "$APP_DIR" | tr '[:upper:]' '[:lower:]')
IMAGE_NAME="${PROJECT_NAME}:latest"

echo "🚀 Iniciando Deploy da Aplicação: $PROJECT_NAME"
echo "📍 Localização: $APP_DIR"

# --- Passo 1: Verificação de Infraestrutura ---
if ! kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "❌ ERRO: Cluster '$CLUSTER_NAME' não encontrado!"
    echo "💡 Execute './bootstrap.sh' primeiro para preparar a infraestrutura."
    exit 1
fi

# --- Passo 2: Build da Aplicação (Maven) ---
echo "📦 Compilando binário Java (Maven)..."
if (cd "$APP_DIR" && mvn clean package -DskipTests); then
    echo "✅ Build Maven concluído com sucesso."
else
    echo "❌ FALHA: Erro na compilação Java."
    exit 1
fi

# --- Passo 3: Build da Imagem Docker ---
echo "🐳 Gerando imagem Docker: $IMAGE_NAME"
if docker build -t "$IMAGE_NAME" "$APP_DIR"; then
    echo "✅ Imagem Docker criada."
else
    echo "❌ FALHA: Erro no Docker Build."
    exit 1
fi

# --- Passo 4: Sincronização com o Cluster ---
echo "🚚 Carregando imagem no Kind..."
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

# --- Passo 5: Deploy no Kubernetes ---
echo "📂 Aplicando manifestos da aplicação..."
# Aplica qualquer arquivo YAML encontrado na pasta do projeto
kubectl apply -f "$APP_DIR/app-deployment.yaml" || \
kubectl apply -f "$APP_DIR/" --selector='!heritage=helm'

# --- Passo 6: Garantia de Atualização (Hot Refresh) ---
echo "🔄 Forçando reinicialização dos Pods..."
# Reinicia o deployment baseado no label 'app' (deve ser igual ao nome da pasta)
kubectl rollout restart deployment -l "app=$PROJECT_NAME" 2>/dev/null || \
kubectl rollout restart deployment "$PROJECT_NAME"

# --- Passo 7: Verificação de Prontidão ---
echo "⏳ Aguardando aplicação ficar pronta..."
kubectl wait --for=condition=available deployment -l "app=$PROJECT_NAME" --timeout=60s

# --- Passo 8: Limpeza Pós-Sucesso ---
echo "🧹 Limpando artefatos temporários..."
rm -rf "$APP_DIR/target"
docker image prune -f

echo "--------------------------------------------------"
echo "✅ DEPLOY FINALIZADO COM SUCESSO!"
echo "🌐 URL: http://localhost:8080"
echo "✅ Verifique o status no K9s."
echo "--------------------------------------------------"
 ```

---

## 🧹 Limpeza

- **Remover o Deployment e o Serviço:**
```bash
  kubectl delete deployment nginx-ultraseven
  kubectl delete svc ultraseven-service
```
- **Remover todos os recursos do namespace atual:**
```bash
  kubectl delete all --all
```
  
- **Apagar Cluster:**
```bash
  kind delete cluster --name ultraseven-cluster
```   
