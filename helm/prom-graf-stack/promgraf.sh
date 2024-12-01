#!/bin/bash

# installation type flag; default = global
installType = 'global'

# add helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# install prometheus-grafana stack
helm install -f values.yaml kube-prometheus-stack prometheus-community/kube-prometheus-stack

# show config opts
helm show values prometheus-community/kube-prometheus-stack