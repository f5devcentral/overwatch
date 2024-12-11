# Project Overwatch

## Introduction

This repo contains all the required manifests and documentation to build a modern observability stack built on opensource software components. This implementation utilizes a Linux Virtual Machine as a Bastion Host to prepare a devops environment with all the necessary tools to required to deploy the pre-configured pre-plumbed observability stack which is comprised of:

  1. Logstash
  2. ElasticSearch
  3. Kibana
  4. AlertManager
  5. Prometheus
  6. Grafana
  7. NodeExporter

This implementation utilizes F5 BigIP Virtual Instances deployed as an auto-scaleset to provide ingress services and ITSG compliant security controls for the solution. You will require between 2 and 5 HP-VE BEST Bundle License keys with IP Intelligence and Threat Campaigns add-ons. Contact you local F5 team for evaluation licenses if you want to kick the tires on this without any financial commmitment.

NB: Autoscaling is not enabled by default. Manual scaling of both the F5 BIG-IP VMSS and the AKS deployments is left up to the user. This example supports up to a maximum of 5 instances in the VMSS. 

## Getting Started

This implementation is designed to deploy into an existing Azure resource-group and properly configured virtual network. If required, use these steps to build these dependencies using the method of your choice:

### Part I: Regions, Resource Groups, VNets, Subnets, NatGW, NSGs
  1. Clone the repo to your local environment.
  2. Create a Resource Group in the Azure region of your choice.
  3. Create 3 Network Security Groups:
      - mgmtNsg (default ruleset)
      - extNsg (default ruleset)
      - intNsg (default ruleset)
  4. Create a NAT Gateway & Public IP address for it.
      - default: Overwatch-natgw-pip
      - default: Overwatch-natgw
  5. Create a VNet with a large address space (/12). 
      - The default name is overwatch-vnet
      - The default CIDR is 10.120.0.0/12
  6. Create 3 Subnets for the F5 BigIP VMSS cluster, associating the corresponding NSG created in Step 3:
      - mgmt-subnet (default: 10.127.254.0/24)
        - associate the Overwatch-natgw created in step 4 with the mgmt-subnet
        - associate the mgmtNsg with this subnet
      - internal-subnet (default: 10.127.253.0/24)
        - associate the intNsg with this subnet
      - external-subnet (default: 10.127.252.0/24)
        - associate the extNsg with this subnet  
### Part II: Bastion Host
  7. From the Azure Marketplace, create a new Linux Virtual Machine using the Ubuntu 22.04-LTS:
      - Create a new resource
      - Search: Ubuntu Server 22.04 LTS
      - On the first search result, click Create
          | Setting | Value |
          |---------|-------|
          |Resource group | Use RG created in Step 2 |
          |Virtual machine name | tux |
          |Region | Canada Central / Canada East |
          |Availability Zone | Zone 1 |
          |Security type | Trusted launch virtual machines |
          |Image | Ubuntu Server 22.04 LTS - x64 Gen2 |
          |Size | Standard_D4s_v3 - 4 vcpus, 16 GiB memory |
          |Authentication Type | SSH public key / password (your choice) |
          |Username | azops |
          |SSH Public key source | Generate new key pair |
          |SSH Key Type | RSA SSH Format |
          |Key  Pair name | tux |
          |Authentication Type | Password (your choice) |
          |Username | azops |
          |Password | Default1235! |
          |Confirm Password | Default123345! |
          |Public Inbound ports | none |
      - At the top of the form, click on Networking
          | Setting | Value |
          |---------|-------|
          |Virtual Network | Overwatch-vnet |
          |Subnet | mgmt-subnet |
          |Public IP | (new) |
          |NIC network security group | none |
          |Enable accelerated networking | true |
          |Load balancing options | none |
      - Click Review + Create
      NB: Once the resource is created, select it and then start the virtual machine
  8. While the VM is booting, edit the mgmtNSG and add a rule to allow inbound SSH connections from your workstation:
      - Inside the resource group created in Step 2, Click on mgmtNSG
      - Click Settings -> Inbound security rules -> Add
        | Setting | Value |
        |---------|-------|
        |Source | My IP Address |
        |Destination | Any |
        |Service | SSH |
        |Action | Allow |
      - Click: Add
### Part III: SSH to the Bastion Host and prepare your build envionment
  9. If using windows, install Windows Terminal along with OpenSSH client (available on the Windows Store) on your local workstation.
  10. Launch a Terminal session, and SSH to the Public IP address of the Bastion Host using the credentials settings supplied in Step 7.
  11. Update the BaseOS and install our DevOps tools:
    - Copy and Paste the commands as show in the repo artifact: https://raw.githubusercontent.com/f5devcentral/overwatch/refs/heads/main/build_ubuntu_vms.sh
    - These commands will perform the following essential tasks:
      - Install all OS updates and security patches
      - Install cli tools: curl, wget, net-tools, python3-pip, ansible, gnupg, git, jq
      - Install devops tools: 
        - Terraform
        - kubectl
        - k9s
        - Azure CLI
        - Filebeat agent
    NB: You will most likely want to reboot the Bastion Host Virtual Machine for any kernel updates to take effect.
  12. Clone this Repo to your Bastion Host:
```bash
    mkdir -p ~/code && cd ~/code && git clone https://github.com/f5devcentral/overwatch.git
```
  13. Customize the default values for the F5 BigIP VMSS configuration
```bash
  cd ~/code/overwatch/terraform/az-auto-scaleset
  cp terraform.tfvars.example terraform.tfvars
  vi/nano terraform.tfvars
```
    NB:  ***CRITICAL*** Set Custom Username and Password and SSH Public Key location values at a minimum. 
    NB:  Customize other values to match your Azure environment.
  14. Customize the default values for the aks-cluster deployment:
```bash
  cd ~/code/overwatch/terraform/az-aks-cluster
  cp terraform.tfvars.example terraform.tfvars
  vi terraform.tfvars
```
    NB:  ***CRITICAL*** Set Custom Username and Password values at a minimum.
  15. Configure CIS with the same credentials configured in Step 13.
```bash
  cd ~/code/overwatch/helm/cis
  vi cis.sh
```
    NB:  ***CRITICAL*** set the user and pass values to match those used when you deployed the F5 BigIP VMSS in Step 15.
### Part IV: Deploy the infrastructure
  16. Deploy the F5 BigIP VMSS:
```bash
  cd ~/code/overwatch/terraform/az-auto-scaleset
  terraform init
  terraform plan
  terraform apply --auto-approve
```
  17. Deploy the AKS Cluster:
```bash
  cd ~/code/overwatch/terraform/az-aks-cluster
  terraform init
  terraform plan
  terraform apply --auto-approve
```
  18. Deploy F5 Container Ingress Services operator:
```bash
  cd ~/code/overwatch/helm/cis
  ./cis.sh
```
  19. Configure kubectl and helm to remotely administer AKS cluster:
```bash
  cd ~/code/overwatch
  vi/nano kubeconfig.sh
```
    Set 'rg' value to match the name of the Resource Group created in Step 2.
    Set 'aks' value to match the name of the AKS cluster created in step 17.
```bash
  ./kubeconfig.sh
```
      NB: You will be prompted to autenticate to the Azure Portal to fetch the credentials needed to remotely mange the AKS cluster
      NB: You may be prompted to accept the Terms and Conditions of the F5 BigIP Azure Marketplace image. This is normal and doesn't have a cost associated with it since we're using a BYOL image type
```bash
  alias k=kubectl
  source <(kubectl completion bash)
  k get pods -A #you should not see any errors
```
Part V: Deploy the modern observability software stack
  20. Deploy ELK Stack:
```bash
  cd ~/code/overwatch/helm/eck-stack
  vi values.yaml (adjust as needed or leave defaults if not sure)
  ./eck.sh
```
  21. Deploy ELK Stack:
```bash
  cd ~/code/overwatch/helm/prom-graf-stack
  vi values.yaml (adjust as needed or leave defaults if not sure)
  ./promgraf.sh
```
  22. Deploy Ingress Custom Resource Defnitions:
```bash
  cd ~/code/overwatch/helm/cis/crds
  #ECK Ingress
  for i in `ls -1 *.yaml`; do (kubectl apply -n elastic-system -f $i)
  #Grafana Ingress
  for i in `ls -1 *.yml`; do (kubectl apply -n elastic-system -f $i)
```
### Part VI
  23. Extract the ElasticSearch admin password using the following command:
```bash
  #Fetch ES Creds
  kibanaUrl=$(kubectl get service elastic-es-http)
  esPass=`kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o jsonpath="{.data.elastic}" |base64 -d`
  echo "URL: ${kibanaUrl}"
  echo "Username: elastic"
  echo "Password: ${esPass}"
  echo ""
```
  24. Extract the Kibana Login URL: 
```bash
  # show grfana admin creds
  grafanaUrl=$(kubectl get service grafana-labs-stack)
  echo "Username: admin"
  echo "Password: `kubectl get secret grafana -n elastic-system -o jsonpath="{.data.admin-password}" |base64 -d`"
  echo ""
```

## Support

For support, please open a GitHub issue.  Note, the code in this repository is community supported and is not supported by F5 Networks.  For a complete list of supported projects please reference [SUPPORT.md](SUPPORT.md).

## Community Code of Conduct

Please refer to the [F5 DevCentral Community Code of Conduct](code_of_conduct.md).

## License

[Apache License 2.0](LICENSE)

## Copyright

Copyright 2014-2020 F5 Networks Inc.

### F5 Networks Contributor License Agreement

Before you start contributing to any project sponsored by F5 Networks, Inc. (F5) on GitHub, you will need to sign a Contributor License Agreement (CLA).

If you are signing as an individual, we recommend that you talk to your employer (if applicable) before signing the CLA since some employment agreements may have restrictions on your contributions to other projects.
Otherwise by submitting a CLA you represent that you are legally entitled to grant the licenses recited therein.

If your employer has rights to intellectual property that you create, such as your contributions, you represent that you have received permission to make contributions on behalf of that employer, that your employer has waived such rights for your contributions, or that your employer has executed a separate CLA with F5.

If you are signing on behalf of a company, you represent that you are legally entitled to grant the license recited therein.
You represent further that each employee of the entity that submits contributions is authorized to submit such contributions on behalf of the entity pursuant to the CLA.
