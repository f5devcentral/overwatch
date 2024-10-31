## Overview

This repo contains all the required manifests and documentation to build a modern observability stack built on opensource software components. The manifests folder contains everything required to deploy a pre-configured pre-plumbed observability stack comprised of:

  1. Logstash
  2. ElasticSearch
  3. Kibana
  4. InfluxDB
  5. Prometheus
  6. Grafana

## Getting Started

  1. Clone the repo to your local environment.
  2. Create an aks/eks/gke/roll-you-own k8s cluster with dynamic storage provisioning support configured and enabled.
  3. Configure kubectl to remotely configure the k8s cluster.
  4. Using your CLI of choice, in the manifests/setup folder, run: kubectl apply -f ./*.yaml --server-side
  5. Using your CLI of choice, in the manifests/elk folder, run: kubectl apply -f ./*.yaml
  6. Using your CLI of choice, in the manifests folder, run: kubectl apply -f ./*.yaml
  7. Extract the ElasticSearch admin password using the following command: PASSWORD=$(kubectl get secret elastic-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
  8. Extract the Kibana Login URL: kibanaUrl=$(kubectl get service elastic-es-http)

  ![image](https://github.com/user-attachments/assets/7ffa68c2-efd7-4638-a104-b431eafa43a6)

    https://<LoadBalancerIp>:<Port>/
  
    Login with username 'elastic' and password retrieved in step 7. 
    
  Happy ELK'ing!

## Installation

Outline the requirements and steps to install this project.

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
