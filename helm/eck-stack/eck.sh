#!/bin/bash

# add helm repo
helm repo add elastic https://helm.elastic.co
helm repo update

# install Elastic CRDs and Operator
helm upgrade --install elastic-operator-crds elastic/eck-operator-crds
kubectl apply -f https://download.elastic.co/downloads/eck/2.15.0/operator.yaml


# install elasticsearch init container DaemonSet
kubectl apply -n elastic-system -f max-map-counter-setter.yaml

# install ECK stack: elasticsearch-kibana-logstash-beats
helm upgrade --install eck-stack-with-logstash elastic/eck-stack -n elastic-system --create-namespace --values ./values.yaml

# show elastic-operator logs
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator