# kubegenesis/src/terraform_templates/local/main.tf.tpl

provider "libvirt" {
  uri = "qemu:///system"
}

variable "cluster_name" { type = string }
variable "ssh_key_path" { type = string }

variable "master_count" { type = number }
variable "master_instance_type" { type = number } # RAM em MB
variable "master_ami" { type = string }

variable "worker_count" { type = number }
variable "worker_instance_type" { type = number } # RAM em MB
variable "worker_ami" { type = string }

variable "gpu_worker_count" { type = number }
variable "gpu_worker_instance_type" { type = number } # RAM em MB
variable "gpu_worker_ami" { type = string }

# Data source para a imagem base (Ubuntu Cloud Image)
data "http" "ubuntu_image" {
  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

resource "libvirt_volume" "os_image" {
  name   = "ubuntu-jammy-cloudinit-${var.cluster_name}"
  source = data.http.ubuntu_image.url
  format = "qcow2"
}

# Cloud-init para configuração inicial (SSH key, sudo )
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "${var.cluster_name}-cloudinit.iso"
  user_data      = templatefile("${path.module}/cloud-init.yaml.tpl", {
    ssh_key = file(var.ssh_key_path)
  })
}

# Instâncias Master
resource "libvirt_domain" "master" {
  count = var.master_count
  name   = "${var.cluster_name}-master-${count.index}"
  memory = var.master_instance_type
  vcpu   = 2 # CPUs
  
  disk {
    volume_id = libvirt_volume.os_image.id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name = "default" # Usar a rede padrão do libvirt
    wait_for_lease = true
  }
  # Para GPU, libvirt tem suporte via hostdev, mas é mais complexo e específico do hardware
  # e não será incluído neste template básico.
}

# Instâncias Worker
resource "libvirt_domain" "worker" {
  count = var.worker_count
  name   = "${var.cluster_name}-worker-${count.index}"
  memory = var.worker_instance_type
  vcpu   = 2
  
  disk {
    volume_id = libvirt_volume.os_image.id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }
}

# Instâncias GPU Worker (sem suporte a GPU real neste template libvirt básico)
resource "libvirt_domain" "gpu_worker" {
  count = var.gpu_worker_count
  name   =
