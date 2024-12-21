#!/bin/bash

# add helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# install prometheus-grafana stack
helm upgrade --install grafana-labs-stack prometheus-community/kube-prometheus-stack -n grafana-system --create-namespace --values ./values.yaml

# show grfana admin creds
echo "Username: admin"
echo "Password: `kubectl get secret grafana -n grafana-system -o jsonpath="{.data.admin-password}" |base64 -d`"
echo ""
