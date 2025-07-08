
---
- name: Common OS Setup for Kubernetes Nodes
  hosts: all
  become: yes
  tasks:
    - name: Update apt cache and upgrade packages
      ansible.builtin.apt:
        update_cache: yes
        upgrade: dist
        autoclean: yes
        autoremove: yes

    - name: Install common packages
      ansible.builtin.apt:
        name:
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
        state: present

    - name: Disable swap
      ansible.builtin.shell: swapoff -a
      when: ansible_swaptotal_mb > 0

    - name: Comment out swap in /etc/fstab
      ansible.builtin.replace:
        path: /etc/fstab
        regexp: 
          '^([^#].*?\sswap\s+sw\s+.*)$'
        replace: '# \1'

    - name: Add kernel parameters for Kubernetes
      ansible.builtin.copy:
        dest: /etc/sysctl.d/k8s.conf
        content: |
          net.bridge.bridge-nf-call-ip6tables = 1
          net.bridge.bridge-nf-call-iptables = 1
          net.ipv4.ip_forward = 1
        owner: root
        group: root
        mode: '0644'

    - name: Apply sysctl parameters without reboot
      ansible.builtin.command: sysctl --system

    - name: Ensure br_netfilter module is loaded
      ansible.builtin.modprobe:
        name: br_netfilter
        state: present

    - name: Ensure overlay module is loaded
      ansible.builtin.modprobe:
        name: overlay
        state: present

    - name: Configure containerd prerequisites (for all nodes)
      ansible.builtin.block:
        - name: Create /etc/modules-load.d/containerd.conf
          ansible.builtin.copy:
            dest: /etc/modules-load.d/containerd.conf
            content: |
              overlay
              br_netfilter
            owner: root
            group: root
            mode: '0644'

        - name: Add Kubernetes apt key
          ansible.builtin.apt_key:
            url: https://pkgs.k8s.io/core:/stable:/v${KUBEG_KUBERNETES_VERSION%.*}/deb/Release.key
            state: present

        - name: Add Kubernetes apt repository
          ansible.builtin.apt_repository:
            repo: deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBEG_KUBERNETES_VERSION%.*}/deb/ /
            state: present
            filename: kubernetes.list

        - name: Install kubelet, kubeadm, and kubectl
          ansible.builtin.apt:
            name:
              - kubelet
              - kubeadm
              - kubectl
            state: present
            update_cache: yes

        - name: Hold kubelet, kubeadm, and kubectl versions
          ansible.builtin.dpkg_selections:
            name: "{{ item }}"
            selection: hold
          loop:
            - kubelet
            - kubeadm
            - kubectl

        - name: Enable and start kubelet service
          ansible.builtin.systemd:
            name: kubelet
            state: started
            enabled: yes


