# --- PASSO 1: Criar o Cluster Kind ---
variable "cluster_name" {
  description    = "O nome do Cluster"
  type           = string
  default        = "ultraseven-cluster"
}
