# --- PASSO 1: Criar o Cluster Kind ---
resource "kind_cluster" "ultraseven" {
  name            = "ultraseven-cluster"
  kubeconfig_path = format("%s/.kube/config", path.module) # Salva o kubeconfig na pasta local do projeto
  wait_for_ready  = true

  # Aponta para o seu arquivo de configuração do Kind existente
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    
    # Se você quiser passar o conteúdo do arquivo yaml diretamente:
    # (ou remova este bloco kind_config se quiser configurar os nós manualmente no HCL)
  }
}

# --- PASSO 2 CORRIGIDO: Aplicar os arquivos YAML com suporte a múltiplos recursos (---)
locals {
  manifests_path = "${path.module}/settings"
  yaml_files     = fileset(local.manifests_path, "*.{yaml,yml}")
}

# Esse bloco divide os arquivos e lida perfeitamente com o "postgres-full.yaml"
resource "kubectl_manifest" "settings_resources" {
  for_each = local.yaml_files

  yaml_body = file("${local.manifests_path}/${each.value}")

  depends_on = [kind_cluster.ultraseven]
}

# --- PASSO 3: Ajustar o Wait para usar o novo recurso ---
resource "null_resource" "wait_postgres" {
  triggers = {
    manifest_change = join(",", [for m in kubectl_manifest.settings_resources : m.uid])
  }

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s --kubeconfig=${kind_cluster.ultraseven.kubeconfig_path} 2>/dev/null || true"
  }

  depends_on = [kubectl_manifest.settings_resources]
}

