#!/bin/bash
rg="sh-Overwatch"
aks="aks-Sentinel-fleet-goblin"
az login
az image terms accept --urn f5-networks:f5-big-ip-byol:f5-big-all-2slot-byol:17.1.1040100
az aks get-credentials --resource-group $rg --name $aks