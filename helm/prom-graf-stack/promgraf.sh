#!/bin/bash

# add helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# install prometheus-grafana stack
helm upgrade --install -f values.yaml grafana-labs-stack prometheus-community/kube-prometheus-stack

# show config opts
helm show values prometheus-community/kube-prometheus-stack