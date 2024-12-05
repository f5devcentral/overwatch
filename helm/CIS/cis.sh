#!/bin/bash

# create k8s secret to store BigIP creds
kubectl create secret generic f5-bigip-ctlr-login -n kube-system --from-literal=username=azops --from-literal=password=Canada123456

# add the f5 helm repo
helm repo add f5-stable https://f5networks.github.io/charts/stable
helm repo update

# install CIS
helm upgrade --install -f values.yaml f5-cis f5-stable/f5-bigip-ctlr


