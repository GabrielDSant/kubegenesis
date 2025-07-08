
---
- name: Configure Kubernetes Control Plane
  hosts: masters
  become: yes
  tasks:
    - name: Initialize Kubernetes cluster (first master only)
      ansible.builtin.shell: |
        kubeadm init \
          --control-plane-endpoint="${KUBEG_CLUSTER_NAME}" \
          --upload-certs \
          --pod-network-cidr=10.244.0.0/16 \
          --kubernetes-version v${KUBEG_KUBERNETES_VERSION}
      args:
        creates: /etc/kubernetes/admin.conf
      when: inventory_hostname == groups['masters'][0]

    - name: Create .kube directory for ubuntu user
      ansible.builtin.file:
        path: /home/ubuntu/.kube
        state: directory
        mode: '0755'
        owner: ubuntu
        group: ubuntu
      when: inventory_hostname == groups['masters'][0]

    - name: Copy admin.conf to ubuntu user .kube directory
      ansible.builtin.copy:
        src: /etc/kubernetes/admin.conf
        dest: /home/ubuntu/.kube/config
        remote_src: yes
        owner: ubuntu
        group: ubuntu
        mode: '0644'
      when: inventory_hostname == groups['masters'][0]

    - name: Generate join command for control plane nodes
      ansible.builtin.shell: kubeadm token create --print-join-command --ttl 0
      register: join_command_cp
      when: inventory_hostname == groups['masters'][0]

    - name: Set join command for control plane nodes fact
      ansible.builtin.set_fact:
        kubeadm_join_command_cp: "{{ join_command_cp.stdout }}"
      when: inventory_hostname == groups['masters'][0]

    - name: Join other control plane nodes to the cluster
      ansible.builtin.shell: "{{ hostvars[groups['masters'][0]].kubeadm_join_command_cp }} --control-plane --upload-certs"
      when: inventory_hostname != groups['masters'][0]

    - name: Install Calico CNI (if enabled)
      ansible.builtin.shell: kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v${KUBEG_ADDON_CALICO_VERSION}/manifests/calico.yaml
      when: KUBEG_ADDON_CALICO_ENABLED == "true" and inventory_hostname == groups['masters'][0]

    - name: Get Kubernetes join command for worker nodes
      ansible.builtin.shell: kubeadm token create --print-join-command
      register: kubeadm_join_command_output
      when: inventory_hostname == groups['masters'][0]

    - name: Set fact for worker join command
      ansible.builtin.set_fact:
        kubeadm_worker_join_command: "{{ kubeadm_join_command_output.stdout }}"
      when: inventory_hostname == groups['masters'][0]

    - name: Copy worker join command to local file
      ansible.builtin.copy:
        content: "{{ hostvars[groups['masters'][0]].kubeadm_worker_join_command }}"
        dest: "/tmp/kubeadm_worker_join_command.sh"
        mode: '0644'
      delegate_to: localhost
      when: inventory_hostname == groups['masters'][0]

    - name: Fetch kubeconfig from first master
      ansible.builtin.fetch:
        src: /etc/kubernetes/admin.conf
        dest: "/tmp/kubeconfig-{{ KUBEG_CLUSTER_NAME }}"
        flat: yes
      when: inventory_hostname == groups['masters'][0]

    - name: Move kubeconfig to ~/.kube/config-{{ KUBEG_CLUSTER_NAME }}
      ansible.builtin.shell: mv "/tmp/kubeconfig-{{ KUBEG_CLUSTER_NAME }}" "/home/ubuntu/.kube/config-{{ KUBEG_CLUSTER_NAME }}"
      delegate_to: localhost
      when: inventory_hostname == groups['masters'][0]

    - name: Set KUBECONFIG environment variable
      ansible.builtin.lineinfile:
        path: /home/ubuntu/.bashrc
        line: "export KUBECONFIG=/home/ubuntu/.kube/config-{{ KUBEG_CLUSTER_NAME }}"
        insertafter: EOF
      delegate_to: localhost
      when: inventory_hostname == groups['masters'][0]

    - name: Source .bashrc to apply KUBECONFIG immediately
      ansible.builtin.shell: source /home/ubuntu/.bashrc
      delegate_to: localhost
      when: inventory_hostname == groups['masters'][0]


