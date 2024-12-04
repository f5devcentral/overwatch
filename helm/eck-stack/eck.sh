#!/bin/bash

# add helm repo
helm repo add elastic https://helm.elastic.co
helm repo update

# install Elastic CRDs and Operator
#helm upgrade --install elastic-operator-crds elastic/eck-operator-crds
helm upgrade --install elastic-operator elastic/eck-operator -n elastic-system --create-namespace


# install elasticsearch init container DaemonSet
kubectl apply -n elastic-system -f max-map-counter-setter.yaml

# install ECK stack: elasticsearch-kibana-logstash-beats
helm upgrade --install elk-stack elastic/eck-stack -n elastic-system --create-namespace --values ./values.yaml

# show elastic-operator logs
echo "Username: elastic"
echo "Password: `kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o jsonpath="{.data.elastic}" |base64 -d`"
echo ""
