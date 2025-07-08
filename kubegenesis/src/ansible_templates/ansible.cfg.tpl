[defaults]
inventory = ./inventory.ini
remote_user = ubuntu
private_key_file = ${KUBEG_SSH_KEY_PATH}

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
control_path = ~/.ansible/cp/%r@%h:%p


