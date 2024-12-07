#!/bin/bash

maxAttempts=100

hecIp=`az network public-ip show --resource-group sh-Overwatch -n Sentinal-lb-pip-c025 |jq .ipAddress |tr -d \"`
hecPort="7080"
hecHost="logstash-hec.f5demo.com"
hecUrl="http://${hecHost}:${hecPort}/"


echo "Using HTTP Event Collector URL: ${hecUrl}"
echo ""
echo "AVR Tests:"
for i in `ls -1 avr/*.json`; do (
    echo "  > $i"
) done;
echo ""

echo " Sending...";
for (( j=0; j < $maxAttempts; j++ )); do (
    for i in `ls -1 avr/*.json`; do (
        echo -n "  > $i : ";
        curl -k -X PUT -H "Content-Type: application/json" \
            -H "Host: ${hecHost}:${hecPort}" \
            --resolve "${hecHost}:${hecPort}:${hecIp}" \
            --data @avr/http.json ${hecUrl} ;
        echo "";
    ) done;
) done;

echo "Done!"
echo ""