kubectl: export rg="sh-Overwatch" && export aks="aks-Sentinal" && az aks get-credentials --resource-group $rg --name $aks
elastic: export elastic_pw=`kubectl get secret es-kibana-secret -o jsonpath="{.data.admin-password}" | base64 --decode`
admin: export grafana_pw=`kubectl get secret grafana -o jsonpath="{.data.admin-password}" | base64 --decode`