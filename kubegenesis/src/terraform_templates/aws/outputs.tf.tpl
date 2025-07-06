# kubegenesis/src/terraform_templates/aws/outputs.tf.tpl

output "master_ips" {
  value = aws_instance.master[*].private_ip
}

output "worker_ips" {
  value = aws_instance.worker[*].private_ip
}

output "gpu_worker_ips" {
  value = aws_instance.gpu_worker[*].private_ip
}
