# kubegenesis/src/terraform_templates/aws/variables.tf.tpl

variable "cluster_name" { type = string }
variable "region" { type = string }
variable "ssh_key_path" { type = string }

variable "master_count" { type = number }
variable "master_instance_type" { type = string }
variable "master_ami" { type = string }

variable "worker_count" { type = number }
variable "worker_instance_type" { type = string }
variable "worker_ami" { type = string }

variable "gpu_worker_count" { type = number }
variable "gpu_worker_instance_type" { type = string }
variable "gpu_worker_ami" { type = string }
