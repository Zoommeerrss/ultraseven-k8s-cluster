# Isola as configurações de rede de borda para os Devs acessarem via Windows/DBeaver
extra_port_mappings = [
  {
    container_port = 30432
    host_port      = 30432
    listen_address = "0.0.0.0"
    protocol       = "tcp"
  },
  {
    # Ponte para a Aplicação Java Quarkus (Swagger-UI / API)
    container_port = 30080
    host_port      = 8080
    listen_address = "0.0.0.0"
    protocol       = "tcp"
  }
]
