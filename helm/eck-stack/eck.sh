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

#ES index component_template
componentUrl="_component_template/component_template_default"
cat <<-EOF >> component_template.json
{
  "template": {
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        }
      }
    }
  }
}
EOF

#ES index runtime_component_template
runtimeUrl="_component_template/runtime_component_template_default"
cat <<-EOF >> runtime_template.json
{
  "template": {
    "mappings": {
      "runtime": { 
        "day_of_week": {
          "type": "keyword",
          "script": {
            "source": "emit(doc['@timestamp'].value.dayOfWeekEnum.getDisplayName(TextStyle.FULL, Locale.ENGLISH))"
          }
        }
      }
    }
  }
}
EOF

#ES index_template
idxUrl="_index_template/index_template_default"
cat <<-EOF >> index_template.json
{
  "index_patterns": ["logstash-hec-*", "logstash-syslog-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
        "index.mapping.total_fields.limit": 10000
    },
    "mappings": {
      "_source": {
        "enabled": true
      },
      "properties": {
        "host_name": {
          "type": "keyword"
        },
        "created_at": {
          "type": "date"
        }
      }
    },
    "aliases": {
      "mydata": { }
    }
  },
  "priority": 500,
  "composed_of": ["component_template_default", "runtime_component_template_default"], 
  "version": 3,
  "_meta": {
    "description": "High Performance default index settings template"
  }
}
EOF

#ES Cluster settings
cluUrl="_cluster/settings"
cat <<-EOF >> cluster.json
{
  "persistent": {
    "search.max_async_search_response_size": "500mb"
  }
}
EOF

#Fetch ES Creds
esPass=`kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o jsonpath="{.data.elastic}" |base64 -d`

#Apply default settings for indexes
for pod in `k describe endpoints elasticsearch-es-http -n elastic-system |grep ' Addresses' |cut -d ":" -f 2 |tr -d ' ' | tr ',' '\n'`; do (
    #component template
    curl -u elastic:${esPass} \
    -k -X PUT -H "Content-type: application/json" https://${pod}:9200/${componentUrl} --data @./component_template.json | jq;
    #runtime template
    curl -u elastic:${esPass} \
    -k -X PUT -H "Content-type: application/json" https://${pod}:9200/${runtimeUrl} --data @./runtime_template.json | jq;
    #index template
    curl -u elastic:${esPass} \
    -k -X PUT -H "Content-type: application/json" https://${pod}:9200/${idxUrl} --data @./index_template.json | jq;
    #cluster settings
    curl -u elastic:${esPass} \
    -k -X PUT -H "Content-type: application/json" https://${pod}:9200/${cluUrl} --data @./cluster.json | jq;
); done;

# old index settings code
#cat <<-EOF >> index.json
#{
#    "settings": {
#        "index.mapping.total_fields.limit": 10000
#    }
#}
#EOF
#curl -u elastic:${esPass} -k -X PUT -H "Content-type: application/json" https://10.120.0.69:9200/logstash-hec-2024.12.04/_settings --data @./index.json

# show elastic-operator logs
echo "Username: elastic"
echo "Password: ${esPass}"
echo ""
