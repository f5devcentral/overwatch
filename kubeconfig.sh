#!/bin/bash
rg="sh-Overwatch"
aks="aks-Sentinel-fleet-goblin"
alias k=kubectl
source <(kubectl completion bash)
az aks get-credentials --resource-group $rg --name $aks