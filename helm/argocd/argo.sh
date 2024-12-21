#!/bin/bash

# add helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# install ArgoCD-HA
helm install --upgrade argocd-stack argo/argo-cd -n argocd --create-namespace --values ./values.yaml

# show elastic-operator logs
argoPass=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
echo "Username: elastic"
echo "Password: ${argoPass}"
echo ""
