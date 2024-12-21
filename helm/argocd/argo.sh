#!/bin/bash

# add helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# install ArgoCD-HA
helm install --upgrade argocd-stack argo-helm/argo-cd -n argocd --create-namespace --values ./values.yaml

function installArgoCd () {
    #ArgoCD Operator Lifecycle Manager
    curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.30.0/install.sh -o install.sh
    chmod +x install.sh
    ./install.sh v0.30.0
    kubectl create -n olm -f deploy/catalog_source.yaml

    #ArgoCD Operator
    kubectl create namespace argocd
    kubectl create -n argocd -f deploy/operator_group.yaml
    kubectl create -n argocd -f deploy/subscription.yaml
    kubectl get installplans -n argocd

    #ArgoCD CRDs
    kubectl apply -k https://github.com/argoproj/argo-cd/manifests/crds\?ref\=stable
}

