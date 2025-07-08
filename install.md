Instalar KVM/libvirt: sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst
Instalar o provedor Terraform libvirt: terraform -chdir=<path_to_terraform_tmp_dir> init (o KubeGenesis faria isso).
Executar kubegenesis create -f meu-cluster-local.yml.
