
---
- name: Join Worker Nodes to Kubernetes Cluster
  hosts: workers
  become: yes
  tasks:
    - name: Join worker node to cluster
      ansible.builtin.shell: "{{ hostvars[groups["masters"][0]].kubeadm_worker_join_command }}"


