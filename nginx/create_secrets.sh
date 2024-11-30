kubectl create secret tls kibana-tls-secret --cert=tls.crt --key=tls.key
kubectl create secret tls grafana-tls-secret --cert=tls.crt --key=tls.key