
#!/bin/bash

# Script wrapper para chamar a função destroy do kubegenesis

# Define o diretório raiz do kubegenesis
KUBEG_ROOT_DIR=$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")

# Chama a função cmd_destroy do script principal kubegenesis
"$KUBEG_ROOT_DIR/bin/kubegenesis" destroy "$@"


