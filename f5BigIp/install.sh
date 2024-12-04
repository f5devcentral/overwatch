

# Unminimize the minimal ubuntu 22.04 LTS image
#sudo unminimize -y
wget https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.53.0/f5-appsvcs-3.53.0-7.noarch.rpm
wget https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.37.0/f5-telemetry-1.37.0-1.noarch.rpm


cat <<-EOF | tmsh -q
create cli transaction;
create /auth user apiuser password Canada12345 shell bash partition-access replace-all-with { all-partitions { role admin } };
submit cli transaction
EOF

restcurl -u azops:Canada123456 https://localhost/mgmt/shared/telemetry/info
restcurl -u azops:Canada123456 https://localhost/mgmt/shared/appsvcs/info

curl -u azops:Canada123456 -X POST -H "Content-type: application/json" http://localhost:8100/mgmt/shared/telemetry/declare --data @./ts.json
curl -u azops:Canada123456 -X POST -H "Content-type: application/json" http://localhost:8100/mgmt/shared/appsvcs/declare --data @./ts_as3.json


restcurl -u azops:Canada123456 -X POST https://localhost/mgmt/shared/appsvcs


tmsh modify analytics global-settings { external-logging-publisher /Common/telemetry_publisher offbox-protocol hsl use-offbox enabled  }
tmsh create ltm profile analytics telemetry-http-analytics { collect-geo enabled collect-http-timing-metrics enabled collect-ip enabled collect-max-tps-and-throughput enabled collect-methods enabled collect-page-load-time enabled collect-response-codes enabled collect-subnets enabled collect-url enabled collect-user-agent enabled collect-user-sessions enabled publish-irule-statistics enabled }
tmsh create ltm profile tcp-analytics telemetry-tcp-analytics { collect-city enabled collect-continent enabled collect-country enabled collect-nexthop enabled collect-post-code enabled collect-region enabled collect-remote-host-ip enabled collect-remote-host-subnet enabled collected-by-server-side enabled }




restcurl -u azops:Canada123456 -X POST http:// --data @./ts.json
restcurl -u azops:Canada123456 -X POST http:// --data @./ts_as3.json