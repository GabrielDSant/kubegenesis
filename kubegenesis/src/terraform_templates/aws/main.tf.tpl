# kubegenesis/src/terraform_templates/aws/main.tf.tpl

provider "aws" {
  region = var.region
}

# Data source para a AMI (ex: Ubuntu 22.04 LTS)
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Data source para a AMI de GPU (ex: Deep Learning AMI - Ubuntu 20.04)
data "aws_ami" "nvidia_gpu" {
  count = var.gpu_worker_count > 0 ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["Deep Learning AMI (Ubuntu 20.04) Version *"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["898081661606"] # Amazon
}


# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Subnets (uma pública e uma privada por AZ para HA)
resource "aws_subnet" "public" {
  count = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = "${var.region}${element(["a", "b"], count.index)}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.cluster_name}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 2}.0/24"
  availability_zone = "${var.region}${element(["a", "b"], count.index)}"
  tags = {
    Name = "${var.cluster_name}-private-subnet-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Route Table para subnets públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (para subnets privadas acessarem a internet)
resource "aws_eip" "nat" {
  count = 2 # Um por AZ para HA
  vpc   = true
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "${var.cluster_name}-nat-${count.index}"
  }
}

# Route Table para subnets privadas
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  tags = {
    Name = "${var.cluster_name}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


# Security Group para o Cluster (SSH, Kubernetes API, NodePort Range)
resource "aws_security_group" "cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Allow SSH, Kubernetes API, and NodePort traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Acesso SSH de qualquer lugar (para lab, em prod restringir)
  }

  ingress {
    from_port   = 6443 # Kubernetes API Server
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Acesso à API de qualquer lugar (para lab, em prod restringir)
  }

  ingress {
    from_port   = 30000 # NodePort range (ajustar se usar outro)
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    self        = true # Allow traffic within the security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.cluster_name}-sg"
  }
}

# Instâncias Master
resource "aws_instance" "master" {
  count = var.master_count
  ami           = var.master_ami != "" ? var.master_ami : data.aws_ami.ubuntu.id
  instance_type = var.master_instance_type
  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id # Masters em subnet privada
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  key_name      = aws_key_pair.deployer.key_name
  associate_public_ip_address = false # Não associar IP público

  tags = {
    Name = "${var.cluster_name}-master-${count.index}"
    Role = "master"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # Tag para CSI drivers
  }
}

# Instâncias Worker
resource "aws_instance" "worker" {
  count = var.worker_count
  ami           = var.worker_ami != "" ? var.worker_ami : data.aws_ami.ubuntu.id
  instance_type = var.worker_instance_type
  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id # Workers em subnet privada
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  key_name      = aws_key_pair.deployer.key_name
  associate_public_ip_address = false

  tags = {
    Name = "${var.cluster_name}-worker-${count.index}"
    Role = "worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Instâncias GPU Worker
resource "aws_instance" "gpu_worker" {
  count = var.gpu_worker_count
  ami           = var.gpu_worker_ami != "" ? var.gpu_worker_ami : data.aws_ami.nvidia_gpu[0].id
  instance_type = var.gpu_worker_instance_type
  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  key_name      = aws_key_pair.deployer.key_name
  associate_public_ip_address = false

  tags = {
    Name = "${var.cluster_name}-gpu-worker-${count.index}"
    Role = "gpu_worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}
