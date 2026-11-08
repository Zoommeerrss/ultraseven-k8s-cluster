# --- PASSO 1: Criar o Cluster Kind ---
variable "cluster_name" {
  description    = "O nome do Cluster"
  type           = string
  default        = "ultraseven-cluster"
}

variable "extra_port_mappings" {
  type = list(object({
    container_port = number
    host_port      = number
    listen_address = string
    protocol       = string
  }))
  default = []
  description = "Mapeamento dinâmico de portas de borda do cluster para o host"
}
