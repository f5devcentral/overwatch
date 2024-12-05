#!/bin/bash

# add helm repo
helm repo add elastic https://helm.elastic.co
helm repo update

# install Elastic CRDs and Operator
#helm upgrade --install elastic-operator-crds elastic/eck-operator-crds
helm upgrade --install elastic-operator elastic/eck-operator -n elastic-system --create-namespace


# install elasticsearch init container DaemonSet
kubectl apply -n elastic-system -f max-map-counter-setter.yaml

# install ECK stack: elasticsearch-kibana-logstash-beats
helm upgrade --install elk-stack elastic/eck-stack -n elastic-system --create-namespace --values ./values.yaml

#adjust index field mapping limit
cat <<-EOF >> index.json
{
    "settings": {
        "index.mapping.total_fields.limit": 5000
    }
}
EOF
curl -u elastic:21OYkMI4gF7101t7wQoJ5m9u -k -X PUT -H "Content-type: application/json" https://10.120.0.69:9200/logstash-hec-2024.12.04/_settings --data @./index.json

# show elastic-operator logs
echo "Username: elastic"
echo "Password: `kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o jsonpath="{.data.elastic}" |base64 -d`"
echo ""
