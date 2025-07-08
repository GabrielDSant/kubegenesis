
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.cluster_name}-key"
  public_key = tls_private_key.deployer.public_key_openssh
}

resource "local_file" "ssh_private_key" {
  content  = tls_private_key.deployer.private_key_pem
  filename = "${var.ssh_key_path}"
  file_permission = "0600"
}


