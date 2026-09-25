output "bootstrap_status" {
  value = <<EOT

✅ BOOTSTRAP CONCLUÍDO COM TERRAFORM!
--------------------------------------------------
🌐 Cluster: ${kind_cluster.ultraseven.name}
🔌 Banco: localhost:5432
✅ Verifique o status no K9s.
🛠️  Próximo passo: Rodar o script de deploy da sua aplicação Java.
--------------------------------------------------
EOT
}
