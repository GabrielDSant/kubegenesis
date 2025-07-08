---
- name: Install NVIDIA GPU Drivers and Container Toolkit
  hosts: gpu_workers
  become: yes
  tasks:
    - name: Add NVIDIA CUDA GPG key
      ansible.builtin.apt_key:
        url: https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub
        state: present

    - name: Add NVIDIA CUDA repository
      ansible.builtin.apt_repository:
        repo: deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ / 
        state: present
        filename: cuda-ubuntu2204

    - name: Install NVIDIA drivers and CUDA toolkit
      ansible.builtin.apt:
        name: 
          - cuda-drivers
          - cuda-toolkit
        state: present
        update_cache: yes

    - name: Add Docker GPG key
      ansible.builtin.apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker repository
      ansible.builtin.apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
        state: present
        filename: docker

    - name: Install nvidia-container-toolkit
      ansible.builtin.apt:
        name: nvidia-container-toolkit
        state: present
        update_cache: yes

    - name: Configure containerd for NVIDIA runtime
      ansible.builtin.shell: |
        containerd config default | sudo tee /etc/containerd/config.toml
        sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        sudo mkdir -p /etc/containerd/certs.d/nvidia_gpu
        sudo systemctl restart containerd
      args:
        creates: /etc/containerd/config.toml

    - name: Restart containerd service
      ansible.builtin.systemd:
        name: containerd
        state: restarted
        enabled: yes


