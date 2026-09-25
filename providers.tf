terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    # CERTIFIQUE-SE DE QUE ESTÁ ASSIM (gavinbunney/kubectl):
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}

# Garanta também que o bloco do provider use o nome correto
provider "kubectl" {
  config_path      = kind_cluster.ultraseven.kubeconfig_path
  load_config_file = true
}
