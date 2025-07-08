# O Conceito: KubeGenesis - Um Framework Opinativo para Kubernetes

## A Proposta de Valor

> "Construir um cluster Kubernetes de produção do zero é complexo. KubeGenesis é uma ferramenta CLI que automatiza a criação de um cluster HA (Altamente Disponível) e configura um ecossistema de ferramentas essenciais (Monitoramento, GitOps, etc.) seguindo as melhores práticas da indústria. Ele gera o código de Infraestrutura como Código (IaC) para você, permitindo personalização total sem aprisionar o usuário."

## Por que isso é impressionante?

KubeGenesis é muito mais do que apenas um laboratório pessoal. Ele demonstra:

- **Visão de Produto**: Você identificou um problema real e projetou uma solução.
- **Habilidades de Engenharia de Software**: Você não está apenas escrevendo scripts, está construindo uma ferramenta robusta, com uma CLI, estrutura de projeto, etc.
- **Domínio Profundo**: Para automatizar e criar um _framework_ para algo, você precisa entender esse algo em um nível muito mais profundo do que apenas para usá-lo.
- **Contribuição para a Comunidade**: Projetos open-source são altamente valorizados.


## Como Usar o KubeGenesis

### Pré-requisitos

Antes de usar o KubeGenesis, certifique-se de ter os seguintes pré-requisitos instalados em sua máquina:

-   **Terraform**: Para provisionar a infraestrutura.
-   **Ansible**: Para configurar os nós do Kubernetes.
-   **kubectl**: Para interagir com o cluster Kubernetes.
-   **Helm**: Para instalar addons no cluster.
-   **`yq`**: Para parsear arquivos YAML (instalado via `pip install yq`).
-   **`jq`**: Para processar JSON (instalado via `sudo apt-get install jq`).
-   **Chave SSH**: Uma chave SSH configurada para acesso às máquinas provisionadas (o caminho deve ser especificado no `kubegenesis.yml`).
-   **Credenciais AWS (se usando AWS)**: Configure suas credenciais AWS (variáveis de ambiente, `~/.aws/credentials`, etc.) para que o Terraform possa provisionar recursos.

### Passos para Criar um Cluster

1.  **Clone o repositório KubeGenesis:**

    ```bash
    git clone https://github.com/GabrielDSant/kubegenesis
    cd kubegenesis
    ```

2.  **Crie seu arquivo de configuração:**

    Copie o arquivo de exemplo e edite-o com suas especificações de cluster. Este arquivo define o provedor de nuvem, a versão do Kubernetes, o número e tipo de nós, e os addons a serem instalados.

    ```bash
    cp kubegenesis/src/kubegenesis.yml.example my-cluster.yml
    # Edite my-cluster.yml com suas configurações
    ```

    **Exemplo de `my-cluster.yml` (para AWS):**

    ```yaml
    config:
      clusterName: my-prod-cluster
      cloudProvider: aws
      region: us-east-1
      kubernetesVersion: 1.28.0
      sshKeyPath: ~/.ssh/my_aws_key.pem # Certifique-se de que esta chave existe e tem permissões 0600

    nodes:
      masters:
        count: 3
        instanceType: t3.medium
        ami: ami-0abcdef1234567890 # Substitua pela AMI ID correta para sua região e SO
      workers:
        count: 3
        instanceType: t3.large
        ami: ami-0abcdef1234567890 # Substitua pela AMI ID correta para sua região e SO
      gpuWorkers:
        count: 0
        instanceType: p3.2xlarge
        ami: ami-0abcdef1234567890 # Substitua pela AMI ID correta para sua região e SO

    addons:
      calico:
        enabled: true
        version: 3.26.1
      argocd:
        enabled: true
        version: 5.36.1
      prometheus:
        enabled: false
        version: 25.2.0
      nvidiaGpuSupport:
        enabled: false
    ```

    **Exemplo de `my-cluster.yml` (para ambiente local com Libvirt/KVM):**

    ```yaml
    config:
      clusterName: my-local-cluster
      cloudProvider: local
      kubernetesVersion: 1.28.0
      sshKeyPath: ~/.ssh/id_rsa # Caminho para a chave SSH privada

    nodes:
      masters:
        count: 1
        instanceType: 4096 # RAM em MB
      workers:
        count: 2
        instanceType: 8192 # RAM em MB
      gpuWorkers:
        count: 0
        instanceType: 0 # RAM em MB

    addons:
      calico:
        enabled: true
        version: 3.26.1
      argocd:
        enabled: false
        version: 5.36.1
      prometheus:
        enabled: false
        version: 25.2.0
      nvidiaGpuSupport:
        enabled: false
    ```

3.  **Crie o cluster:**

    Execute o script `kubegenesis` com o comando `create` e seu arquivo de configuração:

    ```bash
    ./kubegenesis/bin/kubegenesis create my-cluster.yml
    ```

    O script irá:
    -   Provisionar as máquinas virtuais usando Terraform.
    -   Configurar os nós (instalar Docker, kubeadm, kubelet, kubectl) usando Ansible.
    -   Inicializar o cluster Kubernetes e configurar o Control Plane.
    -   Fazer o join dos nós workers ao cluster.
    -   Instalar addons como Calico, Argo CD e Prometheus (se habilitados na configuração).

4.  **Acesse seu cluster:**

    Após a conclusão bem-sucedida, o script irá informar o comando para configurar seu `KUBECONFIG`:

    ```bash
    export KUBECONFIG=~/.kube/config-my-prod-cluster
    kubectl get nodes
    ```

### Passos para Destruir um Cluster

Para destruir um cluster criado pelo KubeGenesis, use o comando `destroy` com o mesmo arquivo de configuração:

```bash
./kubegenesis/bin/kubegenesis destroy my-cluster.yml
```

**ATENÇÃO**: Este comando irá destruir *todos* os recursos de infraestrutura provisionados pelo Terraform para este cluster. Certifique-se de que você realmente deseja fazer isso.

## Estrutura do Projeto

```
. # Raiz do repositório
├── README.md # Documentação principal do projeto
├── exemplo/ # Exemplo de arquivo de configuração
│   └── kubegenesis.yml
└── kubegenesis/ # Código fonte da ferramenta KubeGenesis
    ├── LICENSE
    ├── bin/ # Executáveis da CLI
    │   └── kubegenesis
    ├── docs/ # Documentação interna
    │   └── usage.md
    └── src/ # Código fonte principal
        ├── ansible_templates/ # Templates Jinja2 para playbooks e inventário Ansible
        │   ├── ansible.cfg.tpl
        │   ├── inventory.ini.tpl
        │   └── playbooks/
        │       ├── common.yml.tpl # Configurações comuns de SO e instalação de kubeadm/kubelet/kubectl
        │       ├── control-plane.yml.tpl # Inicialização do Control Plane e join de masters
        │       ├── gpu-setup.yml.tpl # Configuração de drivers NVIDIA para nós GPU
        │       └── worker-join.yml.tpl # Join de workers ao cluster
        ├── commands/ # Scripts wrapper para os comandos da CLI
        │   ├── create.sh
        │   └── destroy.sh
        ├── kubegenesis.yml.example # Exemplo de arquivo de configuração do KubeGenesis
        ├── kubernetes_templates/ # Templates para manifestos Kubernetes (addons, exemplos)
        │   ├── addons/
        │   │   ├── argocd-install.yaml.tpl
        │   │   ├── calico.yaml.tpl
        │   │   └── prometheus.stack.yaml.tpl
        │   └── examples/
        │       └── gpu/
        │           ├── gpu-test-pod.yaml
        │           └── tensorflow-gpu-deployment.yaml
        ├── lib/ # Funções utilitárias para os scripts shell
        │   └── utils.sh
        └── terraform_templates/ # Templates Jinja2 para código Terraform
            ├── aws/ # Templates Terraform para AWS
            │   ├── main.tf.tpl
            │   ├── outputs.tf.tpl
            │   └── variables.tf.tpl
            ├── common/ # Templates Terraform comuns (ex: key pair)
            │   └── key_pair.tf.tpl
            └── local/ # Templates Terraform para ambiente local (Libvirt/KVM)
                ├── cloud-init.yaml.tpl
                └── main.tf.tpl
```

## Próximos Passos e Melhorias

-   **Validação de Configuração**: Implementar validação mais robusta do arquivo `kubegenesis.yml` para garantir que todos os parâmetros necessários estejam presentes e corretos.
-   **Suporte a Outros Provedores**: Estender o suporte a outros provedores de nuvem (GCP, Azure) ou virtualização (VMware, VirtualBox).
-   **Modularização Ansible**: Refatorar os playbooks Ansible em roles mais granulares para melhor reusabilidade e organização.
-   **Testes Automatizados**: Adicionar testes de integração para o processo de criação e destruição do cluster, garantindo a confiabilidade da ferramenta.
-   **Documentação Adicional**: Criar documentação mais detalhada sobre a arquitetura do cluster, decisões de design e solução de problemas.
-   **GitOps Integration**: Aprimorar a integração com GitOps, talvez usando o Argo CD para gerenciar o deploy de aplicações de exemplo após a criação do cluster.




#### Exemplo de `my-cluster.yml` (para Aplicação Laravel em Ambiente Local com Libvirt/KVM):

Este exemplo configura um cluster Kubernetes básico otimizado para o desenvolvimento e teste de uma aplicação Laravel em um ambiente local usando Libvirt/KVM. Ele inclui o Argo CD para facilitar o deploy da sua aplicação via GitOps.

```yaml
config:
  clusterName: laravel-dev-cluster
  cloudProvider: local # Define o provedor como ambiente local (Libvirt/KVM)
  kubernetesVersion: 1.28.0 # Versão do Kubernetes
  sshKeyPath: ~/.ssh/id_rsa # Caminho completo para a chave SSH privada que será usada para acessar as VMs locais

nodes:
  masters:
    count: 1 # Um nó master é suficiente para um ambiente de desenvolvimento/teste local
    instanceType: 4096 # 4GB de RAM para o master
  workers:
    count: 1 # Um nó worker para rodar a aplicação Laravel
    instanceType: 8192 # 8GB de RAM para o worker (considerando PHP, Nginx, MySQL/PostgreSQL em containers)
  gpuWorkers:
    count: 0 # Não é necessário para uma aplicação Laravel típica
    instanceType: 0

addons:
  calico:
    enabled: true # Essencial para a rede do cluster
    version: 3.26.1
  argocd:
    enabled: true # Recomendado para deploy GitOps da aplicação Laravel
    version: 5.36.1
  prometheus:
    enabled: false # Pode ser habilitado se monitoramento for necessário
    version: 25.2.0
  nvidiaGpuSupport:
    enabled: false # Não é necessário
```

**Observações para Aplicações Laravel:**

-   **Recursos**: Os valores de `instanceType` (RAM) são sugestões. Ajuste conforme a necessidade da sua aplicação Laravel e dos serviços que ela utiliza (banco de dados, cache, etc.).
-   **Deploy da Aplicação**: Após a criação do cluster, você pode usar o Argo CD (se `argocd.enabled: true`) para gerenciar o deploy da sua aplicação Laravel no cluster. Você precisará de manifestos Kubernetes (Deployments, Services, Ingresses) para sua aplicação Laravel.
-   **Banco de Dados**: Para um ambiente local, você pode rodar o banco de dados (MySQL, PostgreSQL) como um Pod no Kubernetes ou externamente, dependendo da sua preferência.
-   **Persistência**: Considere a configuração de Persistent Volumes e Persistent Volume Claims para dados do banco de dados ou uploads de arquivos da aplicação Laravel.


