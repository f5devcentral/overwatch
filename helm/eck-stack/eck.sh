#!/bin/bash

# add helm repo
helm repo add elastic https://helm.elastic.co
helm repo update

# install ELK stack
helm install -f values.yaml eck-stack-with-logstash elastic/eck-stack -n elastic-system

# show config opts
helm show values elastic/eck-stack