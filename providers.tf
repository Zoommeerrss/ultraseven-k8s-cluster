# providers.tf
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
    # SUBSTITUA PELO PROVEDOR ATUALIZADO ABAIXO:
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

provider "kubectl" {
  config_path      = kind_cluster.ultraseven.kubeconfig_path
  load_config_file = true
}
