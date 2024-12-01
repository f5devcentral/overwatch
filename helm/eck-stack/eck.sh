#!/bin/bash

# installation type flag; default = global
installType = 'global'

# add helm repo
helm repo add elastic https://helm.elastic.co
helm repo update

# restricted install
if [ $installType == 'restricted']; then
    helm install elastic-operator elastic/eck-operator -n elastic-system --create-namespace \
    --set=installCRDs=false \
    --set=managedNamespaces='{namespace-a, namespace-b}' \
    --set=createClusterScopedResources=false \
    --set=webhook.enabled=false \
    --set=config.validateStorageClass=false
else;
    # global install
    helm install -f values.yaml elastic-operator elastic/eck-operator -n elastic-system --create-namespace
fi;


# Install an eck-managed Elasticsearch and Kibana using the default values, which deploys the quickstart examples.
#helm install -f values.yaml es-kb-quickstart elastic/eck-stack -n elastic-stack --create-namespace

# Install an eck-managed Elasticsearch, Kibana, Beats and Logstash using custom values.
helm install eck-stack-with-logstash elastic/eck-stack \
    --values https://raw.githubusercontent.com/elastic/cloud-on-k8s/2.15/deploy/eck-stack/examples/logstash/basic-eck.yaml -n elastic-stack


# show config opts
helm show values elastic/eck-stack