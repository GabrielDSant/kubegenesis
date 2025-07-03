# kubegenesis/src/templates/project_base/infrastructure/terraform/main.tf
# Este é um template muito simplificado.
# Ele será expandido para suportar diferentes provedores e configurações.

variable "cluster_name" { type = string }
variable "region" { type = string }
variable "master_count" { type = number }
variable "master_instance_type" { type = string }
variable "worker_count" { type = number }
variable "worker_instance_type" { type = string }

# Exemplo de recurso AWS (será substituído por lógica de template mais robusta)
# resource "aws_instance" "master" {
#   count = var.master_count
#   ami           = "ami-0abcdef1234567890" # Substituir por AMI real
#   instance_type = var.master_instance_type
#   tags = {
#     Name = "${var.cluster_name}-master-${count.index}"
#   }
# }

# output "master_ips" {
#   value = aws_instance.master[*].private_ip
# }
