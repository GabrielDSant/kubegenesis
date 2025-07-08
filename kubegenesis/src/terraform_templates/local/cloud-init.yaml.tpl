
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_key}

#cloud-config

# Disable swap
runcmd:
  - [ swapoff, -a ]

# Ensure swap is disabled on reboot
fstab:
  - [ /swapfile, none, swap, sw, 0, 0 ]

# Install necessary packages
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - software-properties-common
  - net-tools
  - iputils-ping
  - vim
  - git

# Configure containerd
write_files:
  - path: /etc/modules-load.d/containerd.conf
    content: |
      overlay
      br_netfilter
    permissions: "0644"
  - path: /etc/sysctl.d/k8s.conf
    content: |
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1
      net.ipv4.ip_forward = 1
    permissions: "0644"

runcmd:
  - [ modprobe, overlay ]
  - [ modprobe, br_netfilter ]
  - [ sysctl, --system ]

  # Add Docker GPG key
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  - chmod a+r /etc/apt/keyrings/docker.gpg

  # Add Docker repository
  - echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Install containerd
  - apt-get update
  - apt-get install -y containerd.io

  # Configure containerd
  - mkdir -p /etc/containerd
  - containerd config default | tee /etc/containerd/config.toml
  - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
  - systemctl restart containerd
  - systemctl enable containerd

  # Add Kubernetes GPG key
  - curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBEG_KUBERNETES_VERSION%.*}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  - chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  # Add Kubernetes repository
  - echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBEG_KUBERNETES_VERSION%.*}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

  # Install kubelet, kubeadm, kubectl
  - apt-get update
  - apt-get install -y kubelet kubeadm kubectl

  # Hold packages
  - apt-mark hold kubelet kubeadm kubectl

  # Enable and start kubelet
  - systemctl enable --now kubelet


