# --- PASSO 1: Criar o Cluster Kind ---
resource "kind_cluster" "ultraseven" {
  name            = var.cluster_name
  kubeconfig_path = format("%s/.kube/config", path.module) # Salva o kubeconfig na pasta local do projeto
  wait_for_ready  = true

  # Aponta para o seu arquivo de configuração do Kind existente
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
  }
}

# --- PASSO 2: Aguardar o Postgres (Gerenciado via Ansible no fluxo sequencial) ---
resource "null_resource" "wait_postgres" {
  # O trigger agora acompanha apenas o ciclo de vida do cluster Kind
  triggers = {
    cluster_id = kind_cluster.ultraseven.id
  }

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s --kubeconfig=${kind_cluster.ultraseven.kubeconfig_path} 2>/dev/null || true"
  }

  depends_on = [kind_cluster.ultraseven]
}