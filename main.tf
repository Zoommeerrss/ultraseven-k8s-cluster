# --- PASSO 1: Criar o Cluster Kind ---
resource "kind_cluster" "ultraseven" {
  name            = var.cluster_name
  kubeconfig_path = format("%s/.kube/config", path.module)
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # Este bloco lê as portas de forma dinâmica sem fixar nada no código
    dynamic "node" {
      for_each = var.extra_port_mappings != null ? [1] : []
      content {
        role = "control-plane"

        dynamic "extra_port_mappings" {
          for_each = var.extra_port_mappings
          content {
            container_port = extra_port_mappings.value.container_port
            host_port      = extra_port_mappings.value.host_port
            listen_address = extra_port_mappings.value.listen_address
            protocol       = extra_port_mappings.value.protocol
          }
        }
      }
    }
  }
}

# --- PASSO 2: Aguardar o Postgres ---
resource "null_resource" "wait_postgres" {
  triggers = {
    cluster_id = kind_cluster.ultraseven.id
  }

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s --kubeconfig=${kind_cluster.ultraseven.kubeconfig_path} 2>/dev/null || true"
  }

  depends_on = [kind_cluster.ultraseven]
}
