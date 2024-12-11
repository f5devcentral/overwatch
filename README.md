## Overview

This repo contains all the required manifests and documentation to build a modern observability stack built on opensource software components. The manifests folder contains everything required to deploy a pre-configured pre-plumbed observability stack comprised of:

  1. Logstash
  2. ElasticSearch
  3. Kibana
  4. AlertManager
  5. Prometheus
  6. Grafana
  7. NodeExporter

NB: Autoscaling is not enabled by default. Manual scaling of both the F5 BIG-IP VMSS and the AKS deployments is left up to the user. This example supports up to a maximum of 5 instances in the VMSS. 

## Getting Started

This implementation is designed to deploy into an existing Azure resource-group and properly configured virtual network. If required, use these steps to build these dependencies using the method of your choice:

Part I: Regions, Resource Groups, VNets, Subnets, NatGW, NSGs
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

Part II: Bastion Host
  7. From the Azure Marketplace, create a new Linux Virtual Machine using the Ubuntu 22.04-LTS:
    - Create a new resource
    - Search: Ubuntu Server 22.04 LTS
    - On the first search result, click Create
      - Resource group: Use RG created in Step 2
      - Virtual machine name: tux
      - Region: Canada Central / Canada East
      - Availability Zone: Zone 1
      - Security type: Trusted launch virtual machines
      - Image: Ubuntu Server 22.04 LTS - x64 Gen2
      - Size: Standard_D4s_v3 - 4 vcpus, 16 GiB memory
      - Authentication Type: SSH public key / password (your choice)
        - Username: azops
        - SSH Public key source: 
          - if SSH Public key auth: Generate new key pair
            - SSH Key Type: RSA SSH Format
        - Key  Pair name: tux
      - Authentication Type: Password (your choice)
        - Username: azops
        - Password: Default1235!
        - Confirm Password: Default123345!
      - Public Inbound ports: none
    - At the top of the form, click on Networking
      - Virtual Network: Overwatch-vnet
      - Subnet: mgmt-subnet
      - Public IP: (new)
      - NIC network security group: none
      - Enable accelerated networking: true
      - Load balancing options: none
    - Click Review + Create
    - Once the resource is created, select it and then start the virtual machine
  8. While the VM is booting, edit the mgmtNSG and add a rule to allow inbound SSH connections from your workstation:
    - Inside the resource group created in Step 2, Click on mgmtNSG
    - Click Settings -> Inbound security rules -> Add
      - Source: My IP Address
      - Destination: Any
      - Service: SSH
      - Action: Allow
      - Click: Add
    
Part III: SSH to the Bastion Host and prepare your build envionment
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
    - You will most likely want to reboot the Bastion Host Virtual Machine for any kernel updates to take effect.
  12. Clone this Repo to your Bastion Host:
    - 'mkdir -p ~/code && cd ~/code && git clone https://github.com/f5devcentral/overwatch.git'
  13. Customize the default values for the F5 BigIP VMSS configuration:
    - cd ~/code/overwatch/terraform/az-auto-scaleset
    - cp terraform.tfvars.example terraform.tfvars
    - vi/nano terraform.tfvars
      - ***CRITICAL*** Set Custom Username and Password and SSH Public Key location values at a minimum
      - customize other values to match your Azure environment
  14. Customize the default values for the aks-cluster deployment:
    - cd ~/code/overwatch/terraform/az-aks-cluster
    - cp terraform.tfvars.example terraform.tfvars
    - vi/nano terraform.tfvars
      - ***CRITICAL*** Set Custom Username and Password values at a minimum
  15. Configure CIS with the same credentials configured in Step 13.
    - cd ~/code/overwatch/helm/cis
    - vi cis.sh
      - set the user and pass values to match those used when you deployed the F5 BigIP VMSS in Step 15

Part IV: Deploy the infrastructure
  16. Deploy the F5 BigIP VMSS:
    - cd ~/code/overwatch/terraform/az-auto-scaleset
    - terraform init
    - terraform plan
    - terraform apply --auto-approve
    - Make note of the final outputs with information such as Public IPs for remotely managing the f5 BigIP instances
  17. Deploy the AKS Cluster:
    - cd ~/code/overwatch/terraform/az-aks-cluster
    - terraform init
    - terraform plan
    - terraform apply --auto-approve
    - Make note of the final outputs with information such as Public IPs for remotely managing the aks cluster node instances
  18. Deploy F5 Container Ingress Services operator:
    - cd ~/code/overwatch/helm/cis
    - ./cis.sh
  19. Configure kubectl and helm to remotely administer AKS cluster:
    - cd ~/code/overwatch
    - vi/nano kubeconfig.sh
    - Set 'rg' value to match the name of the Resource Group created in Step 2.
    - Set 'aks' value to match the name of the AKS cluster created in step 17.
    - ./kubeconfig.sh 
      - NB: You will be prompted to autenticate to the Azure Portal to fetch the credentials needed to remotely mange the AKS cluster
      - NB: You may be prompted to accept the Terms and Conditions of the F5 BigIP Azure Marketplace image. This is normal and doesn't have a cost associated with it since we're using a BYOL image type
    - alias k=kubectl
    - source <(kubectl completion bash)
    - k get pods -A #you should not see any errors

Part V: Deploy the modern observability software stack
  20. Deploy ELK Stack:
    - cd ~/code/overwatch/helm/eck-stack
    - vi values.yaml (adjust as needed or leave defaults if not sure)
    - ./eck.sh
    - NB: make note of the credentials to login to ElasticSearch Kibana WebUI
  21. Deploy ELK Stack:
    - cd ~/code/overwatch/helm/prom-graf-stack
    - vi values.yaml (adjust as needed or leave defaults if not sure)
    - ./promgraf.sh
    - NB: make note of the credentials to login to Grafana WebUI
  22. Deploy Ingress Custom Resource Defnitions:
    - cd ~/code/overwatch/helm/cis/crds
    - vi values.yaml (adjust as needed or leave defaults if not sure)
    - ./promgraf.sh
    - NB: make note of the credentials to login to Grafana WebUI

Part VI

  7. Extract the ElasticSearch admin password using the following command:
                            PASSWORD=$(kubectl get secret elastic-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')  
  8. Extract the Kibana Login URL: kibanaUrl=$(kubectl get service elastic-es-http)

  ![image](https://github.com/user-attachments/assets/7ffa68c2-efd7-4638-a104-b431eafa43a6)

    https://<LoadBalancerIp>:<Port>/
  
    Login with username 'elastic' and password retrieved in step 7. 
    
  Happy ELK'ing!

## Installation

  1. Create a Resource Group (RG) in the Azure region of your choice. Make note of the name and the region you chose.
  2. Create a new Virtual Network (VNET) in the RG created in step 1: 10.112.0.0/12
  3. Create three new Network Security Groups in the RG created in step 1: 
    - mgmtNsg: 10.127.254.0/24
    - extNsg: 10.127.252.0/24
    - intNsg: 10.127.253.0/24

  4. Create a three new Subnets in the VNET created in step 2:
    - mgmt-subnet: 10.127.254.0/24
    - external-subnet: 10.127.252.0/24
    - internal-subnet: 10.127.253.0/24

  5. Create 

## Usage

Outline how the user can use your project and the various features the project offers.

## Development

Outline any requirements to setup a development environment if someone would like to contribute.  You may also link to another file for this information.

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
