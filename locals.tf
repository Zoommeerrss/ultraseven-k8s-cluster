# Busca os arquivos .yml
locals {
  manifests_path = "${path.module}/settings"
  yaml_files     = fileset(local.manifests_path, "*.{yaml,yml}")
}
