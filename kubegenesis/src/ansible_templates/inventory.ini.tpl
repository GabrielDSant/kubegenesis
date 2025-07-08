[masters]
${KUBEG_MASTER_IPS}

[workers]
${KUBEG_WORKER_IPS}

[gpu_workers]
${KUBEG_GPU_WORKER_IPS}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=${KUBEG_SSH_KEY_PATH}
ansible_python_interpreter=/usr/bin/python3


