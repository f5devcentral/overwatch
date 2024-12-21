#!/bin/bash -x

# NOTE: Startup Script is run once / initialization only (Cloud-Init behavior vs. typical re-entrant for Azure Custom Script Extension )
# For 15.1+ and above, Cloud-Init will run the script directly and can remove Azure Custom Script Extension


mkdir -p  /var/log/cloud /config/cloud /var/config/rest/downloads


LOG_FILE=/var/log/cloud/startup-script.log
[[ ! -f $LOG_FILE ]] && touch $LOG_FILE || { echo "Run Only Once. Exiting"; exit; }
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1


### write_files:
# Download or Render BIG-IP Runtime Init Config

cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
---
runtime_parameters:
  - name: HOST_NAME
    type: metadata
    metadataProvider:
      environment: azure
      type: compute
      field: name
  - name: REGION
    type: url
    value: http://169.254.169.254/metadata/instance/compute/location?api-version=2021-05-01&format=text
    headers:
      - name: Metadata
        value: true
  - name: USER_NAME
    type: static
    value: ${f5_username}
  - name: ADMIN_PASS
    type: static
    value: ${f5_password}
  - name: SSH_KEYS
    type: static
    value: ${ssh_keypair}
  - name: LAW_ID
    type: static
    value: ${law_id}
  - name: LAW_PRIMKEY
    type: static
    value: ${law_primkey}
  - name: GATEWAY_EXTERNAL
    type: metadata
    metadataProvider:
      environment: azure
      type: network
      field: ipv4
      index: 1
      ipcalc: first
  - name: SELF_IP_EXTERNAL
    type: static
    value: ${self_ip_external}
  - name: SELF_IP_INTERNAL
    type: static
    value: ${self_ip_internal}
  - name: REMOTE_HOST
    type: static
    value: ${remote_host}
  - name: DNS_SERVER
    type: static
    value: ${dns_server}
  - name: NTP_SERVER
    type: static
    value: ${ntp_server}
  - name: TIMEZONE
    type: static
    value: ${timezone}
  - name: HOST1
    type: static
    value: ${host1}
  - name: HOST2
    type: static
    value: ${host2}
pre_onboard_enabled:
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 1000
      - /usr/bin/setdb restjavad.useextramb true
      - /usr/bin/setdb setup.run false
extension_packages:
  install_operations:
    - extensionType: do
      extensionVersion: ${DO_VER}
      extensionUrl: ${DO_URL}
    - extensionType: as3
      extensionVersion: ${AS3_VER}
      extensionUrl: ${AS3_URL}
    - extensionType: ts
      extensionVersion: ${TS_VER}
      extensionUrl: ${TS_URL}
extension_services:
  service_operations:
    - extensionType: do
      type: inline
      value:
        schemaVersion: 1.0.0
        class: Device
        async: true
        label: Onboard BIG-IP into an HA Pair
        Common:
          class: Tenant
          dbVars:
            class: DbVariables
            restjavad.useextramb: true
            provision.extramb: 1000
            config.allow.rfc3927: enable
            ui.advisory.enabled: true
            ui.advisory.color: blue
            ui.advisory.text: ${HOST_NAME}.example.com
            tmm.tcl.rule.node.allow_loopback_addresses: true
          mySystem:
            autoPhonehome: true
            class: System
            hostname: ${HOST_NAME}.f5demo.com
          ${USER_NAME}:
            class: User
            partitionAccess:
              all-partitions:
                role: admin
            password: ${ADMIN_PASS}
            shell: bash
            userType: regular
            keys:
              - ${SSH_KEYS}
          myDns:
            class: DNS
            nameServers:
              - ${DNS_SERVER}
              - 2001:4860:4860::8844
            search:
              - f5.com
          myNtp:
            class: NTP
            servers:
              - ${NTP_SERVER}
              - 1.pool.ntp.org
              - 2.pool.ntp.org
            timezone: ${TIMEZONE}
          myProvisioning:
            class: Provision
            ltm: nominal
          external:
            class: VLAN
            tag: 4094
            mtu: 1500
            interfaces:
              - name: 1.1
                tagged: false
          external-localself:
            class: SelfIp
            address: ${SELF_IP_EXTERNAL}/24
            vlan: external
            allowService: default
            trafficGroup: traffic-group-local-only
          internal:
            class: VLAN
            tag: 4093
            mtu: 1500
            interfaces:
              - name: 1.2
                tagged: false
          internal-localself:
            class: SelfIp
            address: ${SELF_IP_INTERNAL}/24
            vlan: internal
            allowService: default
            trafficGroup: traffic-group-local-only
          default:
            class: Route
            gw: ${GATEWAY_EXTERNAL}
            network: default
            mtu: 1500
          configsync:
            class: ConfigSync
            configsyncIp: /Common/internal-localself/address
          failoverAddress:
            class: FailoverUnicast
            address: /Common/internal-localself/address
          failoverGroup:
            class: DeviceGroup
            type: sync-only
            members:
              - ${HOST1}.example.com
              - ${HOST2}.example.com
            owner: /Common/failoverGroup/members/0
            autoSync: false
            saveOnAutoSync: false
            networkFailover: true
            fullLoadOnSync: false
            asmSync: true
          trust:
            class: DeviceTrust
            localUsername: ${USER_NAME}
            localPassword: ${ADMIN_PASS}
            remoteHost: ${REMOTE_HOST}
            remoteUsername: ${USER_NAME}
            remotePassword: ${ADMIN_PASS}
    - extensionType: as3
      type: inline
      value:
        class: AS3
        action: deploy
        persist: true
        declaration:
          class: ADC
          schemaVersion: 3.16.0
          remark: Configure BIG-IP Common/Shared objects
          Common:
              Shared:
                  class: Application
                  template: shared
                  maintenance_rule:
                      remark: Default Maintenance iRule
                      class: iRule
                      iRule: |-
                          when HTTP_REQUEST {
                              HTTP::respond 200 content "<html><head><title>Maintenance</title></head><body><strong>This site is in maintenance now.</strong></body></html>"
                          }
                  wildcardAddress:
                      class: Service_Address
                      virtualAddress: 0.0.0.0
                  lb_healthProbe_rule:
                      remark: Respond to LB healthProbe
                      class: iRule
                      iRule: |-
                          when CLIENT_ACCEPTED {
                            TCP::close
                          }
                  lb_healthProbe_vs:
                      class: Service_TCP
                      remark: LB Health Probe VS
                      virtualPort: 666
                      virtualAddresses:
                          -
                              use: wildcardAddress
                      iRules:
                          - lb_healthProbe_rule
                  telemetry_local_rule:
                      remark: Only required when TS is a local listener
                      class: iRule
                      iRule: |-
                          when CLIENT_ACCEPTED {
                            node 127.0.0.1 6514
                          }
                  telemetry_local:
                      remark: Only required when TS is a local listener
                      class: Service_TCP
                      virtualAddresses:
                          - 255.255.255.254
                      virtualPort: 6514
                      iRules:
                          - telemetry_local_rule
                  telemetry:
                      class: Pool
                      members:
                          -
                              enable: true
                              serverAddresses:
                                  - 255.255.255.254
                              servicePort: 6514
                      monitors:
                          -
                              bigip: /Common/tcp
                  telemetry_hsl:
                      class: Log_Destination
                      type: remote-high-speed-log
                      protocol: tcp
                      pool:
                          use: telemetry
                  telemetry_formatted:
                      class: Log_Destination
                      type: splunk
                      forwardTo:
                          use: telemetry_hsl
                  telemetry_publisher:
                      class: Log_Publisher
                      destinations:
                          -
                              use: telemetry_formatted
                  telemetry_traffic_log_profile:
                      class: Traffic_Log_Profile
                      responseSettings:
                          responseEnabled: true
                          responseProtocol: mds-tcp
                          responsePool:
                              use: telemetry
                          requestTemplate: >-
                              event_source="request_logging",hostname="$BIGIP_HOSTNAME",client_ip="$CLIENT_IP",server_ip="$SERVER_IP",http_method="$HTTP_METHOD",http_uri="$HTTP_URI",virtual_name="$VIRTUAL_NAME",event_timestamp="$DATE_HTTP"
                          responseTemplate: >-
                              event_source="response_logging",hostname="$BIGIP_HOSTNAME",client_ip="$CLIENT_IP",server_ip="$SERVER_IP",http_method="$HTTP_METHOD",http_uri="$HTTP_URI",response_msec="$RESPONSE_MSEC",response_size="RESPONSE_SIZE",virtual_name="$VIRTUAL_NAME",event_timestamp="$DATE_HTTP"
                  telemetry_security_log_profile:
                      class: Security_Log_Profile
                      application:
                          localStorage: false
                          remoteStorage: splunk
                          protocol: tcp
                          servers:
                              -
                                  address: 255.255.255.254
                                  port: '6514'
                          storageFilter:
                              requestType: illegal-including-staged-signatures
                  hsl_security_log_profile:
                      class: Security_Log_Profile
                      application:
                          localStorage: false
                          remoteStorage: splunk
                          protocol: tcp
                          servers:
                              -
                                  address: ${syslogRemoteAddr}
                                  port: '7514'
                          storageFilter:
                              requestType: all
          INET:
              class: Tenant
              IpFwding:
                  class: Application
                  template: generic
                  IpFwdingSvc:
                      class: Service_Forwarding
                      remark: IP Forwarding Virtual Server
                      virtualAddresses:
                          -
                              use: /Common/Shared/wildcardAddress
                      virtualPort: 0
                      forwardingType: ip
                      layer4: tcp
                      profileL4: basic
                      allowVlans:
                          -
                              bigip: /Common/internal
          SRA:
              class: Tenant
              Webtop:
                  class: Application
                  template: https
                  serviceMain:
                      class: Service_HTTPS
                      redirect80: false
                      virtualAddresses:
                          -
                              use: /Common/Shared/wildcardAddress
                      virtualPort: 10443
                      snat: none
                      profileTCP:
                          bigip: /Common/f5-tcp-progressive
                      profileHTTP:
                          use: webtop_http
                      clientTLS:
                          bigip: /Common/serverssl-insecure-compatible
                      serverTLS: webtop_clientssl
                      policyWAF:
                          use: Ingress_WAF_Policy
                      profileTrafficLog:
                          use: /Common/Shared/telemetry_traffic_log_profile
                      securityLogProfiles:
                          -
                              bigip: /Common/Log all requests
                          -
                              use: /Common/Shared/telemetry_security_log_profile
                      allowVlans:
                          -
                              bigip: /Common/external
                  webtop_http:
                      class: HTTP_Profile
                      hstsInsert: true
                      hstsPreload: true
                  Ingress_WAF_Policy:
                      class: WAF_Policy
                      url: >-
                          https://raw.githubusercontent.com/f5devcentral/overwatch/f5BigIp/ingress-web.xml
                      ignoreChanges: true
                  webtop_clientssl:
                      certificates:
                          -
                              certificate: Wildcard_certificate
                      ciphers: DEFAULT
                      requireSNI: false
                      class: TLS_Server
                  Wildcard_certificate:
                      class: Certificate
                      remark: in practice we recommend using a passphrase
                      certificate: |-
                          -----BEGIN CERTIFICATE-----
                          MIIDtTCCAp2gAwIBAgIBAzANBgkqhkiG9w0BAQsFADBGMQswCQYDVQQGEwJVUzET
                          MBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UECgwJTXlDb21wYW55MQ4wDAYDVQQD
                          DAVsYWJDQTAeFw0xOTA0MjUyMzM3NDVaFw0yOTA0MjIyMzM3NDVaMF8xCzAJBgNV
                          BAYTAkNBMRAwDgYDVQQIEwdPbnRhcmlvMRQwEgYDVQQKEwtGNSBOZXR3b3JrczEO
                          MAwGA1UECxMFU2FsZXMxGDAWBgNVBAMTD3dlYnRvcC5mNXNlLmNvbTCCASIwDQYJ
                          KoZIhvcNAQEBBQADggEPADCCAQoCggEBAO6mWzsOY0UuRzSiVU65gmlSit4d7tW4
                          E/kWYY3LT/dxG2V/kzHhO70amNCTDVv5oAKkToLYCdJNWWxEI+EgUigDtg/v4E1R
                          H0KEQdGC6RHnYK8kOmWWm9Pminh1P1o03QiJ41zj5KcyFYJq4pFRctN5iPs0+F/Y
                          5JBDbPcnuk3OuRLxI67tPwqAQQurXcvGzCYF1y1zxlHxxWyUbuTdCo3GeO2Vo3bN
                          MSTSj9hmxc8QEXif1qA/KDnLtY+IemptJT5aC0WZRwp2lncKOpSLcMcdQAprxHYA
                          6LLkztNqVwCXQFjA7zfVRXV63JGhjV+oR4O8yemLffUVydihXzcsruMCAwEAAaOB
                          lDCBkTAJBgNVHRMEAjAAMB0GA1UdDgQWBBRjzhMuUopHVdDvj9xvCskIPacvQzAf
                          BgNVHSMEGDAWgBQMgRSSF2oS8RCZJADBj3YSv90EsTAOBgNVHQ8BAf8EBAMCBeAw
                          NAYDVR0lAQH/BCowKAYIKwYBBQUHAwIGCCsGAQUFBwMBBggrBgEFBQcDAwYIKwYB
                          BQUHAwQwDQYJKoZIhvcNAQELBQADggEBAKxtUE9tImn6MF0E2RNYeaTkIyCozjPw
                          ARofuW4eE5VKoZyq8JCbzUG44yT8gCSAj24LYuM7mk9CceHpu4pSyLHuptP1W8ZT
                          zpy4BPHaeFoJZCgBW8KkOdlW/4WRTmbfG3YaxPClOj7f5P4Tkw2XaftPJqQWZnCx
                          pEBU8e5AVOSmV1/vkhEi5FjV1aCXEm2DH9TJQtxABKGCaNtwnS701mmJH0HWlDSm
                          MyBI/jTOO2XMoWGEzL9pIMiPPGZZbGWUIfvfhsgBFnJoSUa9ijteR5CLhX7DIfAl
                          juMTHgWmsN80SOIEUaLYNfeFQxkgL0uVc8nzc3JGN+78h+Ktg4piRCM=
                          -----END CERTIFICATE-----
                      privateKey: |-
                          -----BEGIN PRIVATE KEY-----
                          MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDupls7DmNFLkc0
                          olVOuYJpUoreHe7VuBP5FmGNy0/3cRtlf5Mx4Tu9GpjQkw1b+aACpE6C2AnSTVls
                          RCPhIFIoA7YP7+BNUR9ChEHRgukR52CvJDpllpvT5op4dT9aNN0IieNc4+SnMhWC
                          auKRUXLTeYj7NPhf2OSQQ2z3J7pNzrkS8SOu7T8KgEELq13LxswmBdctc8ZR8cVs
                          lG7k3QqNxnjtlaN2zTEk0o/YZsXPEBF4n9agPyg5y7WPiHpqbSU+WgtFmUcKdpZ3
                          CjqUi3DHHUAKa8R2AOiy5M7TalcAl0BYwO831UV1etyRoY1fqEeDvMnpi331FcnY
                          oV83LK7jAgMBAAECggEAE06WFuMFGPWzgQiZCjNr34V0AqA9UEECLKao4cXPBF+8
                          LavyhpiIMrZSIp2i+Qvq7AvK5j8AHGlxkJa6qF3rB521PvjTFq43bzQv9vk2TeKA
                          KesuZkWW+b+u+CvUIkIgl65AHKW7O+OLZe+rwMHsHju430nbxjVP2HP7/srSAbVN
                          t3yyXPmI4VSB2P8NzkYCzr/B46LcS/2OBno9iwjQwDspQNJhpUmxPsFfG0OS0WWh
                          qLgpUvG8GEPkCv8fRjjrqh9iJ3kZOpmv5nQ1OE0ypwYoPhJDiJAAZiXRtPImoM06
                          2M6CbvtdunRuVvVNBYgu75jRgunZycQJP48tWWcWsQKBgQD7/X1WKBIqJRZcDYTf
                          8pHFDzZxhDOpYX31vddk7A3xv9XvqQVCu6hkbFvMu5b80AOeYlo2SCvaA97sS7Bp
                          bafoT6ZCwBztEBjk9v+X0LOSg847c/ik3+M9Nsnpv9N0qdjGtPgm8Kb15PaiHYAH
                          T6kLkvYCFS5G17B2sVoOoWg7fQKBgQDycoX2+FPMPFqUesZ3BlAcZM8sVFTg1VL6
                          RGesJLrT/3ueOUiCWjjcJlPodBNg2Y8N3hQV0CdwGxR14nKoVw0vpv+r/iJp1F7s
                          sGqjtMIw6fHdqPdX2GIvraIxU+j8p94R1ACii3aztqcluJ1S8CsNmUxgUoMJKtO/
                          tvNB4Pjh3wKBgELz/kpXCUSDaCZ7PRPXup12RkvxCVz212Xk1AcvpSDXjLtJ2Gj7
                          vWk5VUbXjO2NQ3jgvwFvOZ+Kqb90+OF6TkOubgmMS+M9BLBJZG3s+Nl0BebMEIOW
                          LSWFmi5uVnvH6R4a1VhbVrE87b7zQaIvq0W0/YJeKFaQVoWi57+9aRltAoGBANV/
                          5FjH9YM04s8+Dudht8pJO+ddnCEhuiCJfIIrFhr6MHH1H9UqfkffuKRLE4WGEGO1
                          3RoYY6JlNm9ZKn7zqbj85ske0k8/pRfpgv8Gfrt0SHlaAfZppo016k5mBhX3/abV
                          enmpNq6reiXNnT0cIc2n4YoxHxNDk5SQF0c8Re8hAoGATtdkvUp4f6A4v9ppdJZs
                          pz7M6/NbKGJH9F3GZseSKTBKgtndiBugrfePOrcdC+4O0i33lvWDOs70kREC4wCG
                          XMt36aS9Z384Pl7Z7FhiVQrTF2ZuRP/6v1r3iJDHixmJYQzjBO2Zh1D7Sf39BxOv
                          2h0dFcPMKaZcLsXTFH1qS0I=
                          -----END PRIVATE KEY-----
              WebSSHProxy:
                  class: Application
                  template: http
                  serviceMain:
                      class: Service_HTTP
                      virtualPort: 10022
                      snat: none
                      profileTCP:
                          bigip: /Common/f5-tcp-progressive
                      virtualAddresses:
                          - ${webssh_vs_addr}
                      iRules:
                          -
                              bigip: /Common/WebSSH2_plugin/webssh2_node
                      allowVlans:
                          -
                              bigip: /Common/external
              - extensionType: ts
                type: inline
                value:
                  class: Telemetry
                  My_System:
                      class: Telemetry_System
                      systemPoller:
                          interval: 60
                          actions:
                              -
                                  setTag:
                                      facility: ECK-Azure-AKS
                                  locations:
                                      system: true
                  controls:
                      class: Controls
                      logLevel: info
                  My_Poller:
                      class: Telemetry_System_Poller
                      interval: 0
                  My_Listener:
                      class: Telemetry_Listener
                      port: 6514
                  metrics:
                      class: Telemetry_Pull_Consumer
                      type: Prometheus
                      systemPoller:
                          - My_Poller
                  My_Consumer:
                      class: Telemetry_Consumer
                      type: Generic_HTTP
                      host: ${HEC_Addr}
                      protocol: http
                      port: 7080
                      path: /
                      method: POST
                      headers:
                          -
                              name: content-type
                              value: application/json
                      outputMode: processed
post_onboard_enabled:
  - name: misc
    type: inline
    commands:
    - tmsh save sys config
EOF

# Download WebSSH Plugin
for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L ${WEBSSH_URL} -o "/var/config/rest/downloads/webssh.tgz" && break || sleep 10
done

# Download BIG-IP Runtime Init
for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L ${INIT_URL} -o "/var/config/rest/downloads/f5-bigip-runtime.gz.run" && break || sleep 10
done

# Remove comment to do silly debugging on BIG-IP Runtime init
#export F5_BIGIP_RUNTIME_INIT_LOG_LEVEL=silly
#export F5_BIGIP_RUNTIME_EXTENSION_INSTALL_DELAY_IN_MS=60000

# Install BIG-IP Runtime Init
bash /var/config/rest/downloads/f5-bigip-runtime.gz.run -- '--cloud azure'

# Run BIG-IP Runtime Init and Process YAML
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml

# Run custom base config installation
#check for MCPD subsystem to be ready
function checkMcpd () {
    CNT=0
    while [ $CNT -lt 120 ]; do echo "Checking MCPD state..."
        tmsh -a show sys mcp-state field-fmt | grep -q running
    if [ "$?" == 0 ]; then
        echo "Got phase running! MCPD Ready!"
        break
    fi
    echo "MCPD is NOT ready yet..."
    CNT=$[$CNT+1]
    sleep 10
    done 
}
checkMcpd
function checkAS3() {
    # Check AS3 Ready
    count=0
    while [ $count -le 4 ]
    do
    as3Status=$(restcurl -u $CREDS -X GET $as3CheckUrl | jq -r .code)
    if  [ "$as3Status" == "null" ] || [ -z "$as3Status" ]; then
        type=$(restcurl -u $CREDS -X GET $as3CheckUrl | jq -r type )
        if [ "$type" == "object" ]; then
            as3Status="200"
        fi
    fi
    if [[ $as3Status == "200" ]]; then
        version=$(restcurl -u $CREDS -X GET $as3CheckUrl | jq -r .version)
        echo "As3 $version online "
        break
    elif [[ $as3Status == "404" ]]; then
        echo "AS3 Status $as3Status"
        bigstart restart restnoded
        sleep 60
        bigstart status restnoded | grep running
        status=$?
        echo "restnoded:$status"
    else
        echo "AS3 Status $as3Status"
        count=$[$count+1]
    fi
    sleep 10
    done
}
function checkTS() {
    # Check TS Ready
    count=0
    while [ $count -le 4 ]
    do
    tsStatus=$(curl -si -u $CREDS http://localhost:8100$tsCheckUrl | grep HTTP | awk '{print $2}')
    if [[ $tsStatus == "200" ]]; then
        version=$(restcurl -u $CREDS -X GET $tsCheckUrl | jq -r .version)
        echo "Telemetry Streaming $version online "
        break
    else
        echo "TS Status $tsStatus"
        count=$[$count+1]
    fi
    sleep 10
    done
}
#check MCPD after running DO
checkMcpd

function runTS () {
    # make task
    taskOut=$(curl -s -u $CREDS -H "Content-Type: Application/json" -H 'Expect:' -X POST http://localhost:8100$tsUrl -d @/config/ts.json)
    sleep 1
    # check task code
    taskResult=$(echo $taskOut |jq -r .message)
    echo "Task status: $taskResult"
}

#  run TS
count=0
while [ $count -le 4 ]
do
    tsStatus=$(checkTS)
    echo "TS check status: $tsStatus"
    if [[ $tsStatus == *"online"* ]]; then
        echo "running TS"
        runTS
        echo "done with TS"
        results=$(restcurl -u $CREDS $tsUrl | jq -r .message)
        echo "TS results: $results"
        break
    elif [ "$count" -le 2 ]; then
        echo "Status code: $tsStatus  TS not ready yet..."
        count=$[$count+1]
        sleep 3
    else
        echo "TS API Status $tsStatus"
        break
    fi
done
#
function installWebSSH () {
    echo "WebSSH ILX Plugin installation starting..."
    tmsh create ilx workspace WebSSH2
    cd /var/ilx/workspaces/Common/WebSSH2
    result=$(tar -zxvf /var/tmp/$webssh_file)
    tmsh create ilx plugin WebSSH2_plugin from-workspace WebSSH2
    echo "installation complete"
}
if [ "$deviceId" -eq 1 ]; then 
    echo "Installing WebSSH ILX Plugin"
    installWebSSH
else
    echo "Not installing WebSSH ILX Plugin: $deviceId is not primary"
fi
#
function runAS3 () {
    count=0
    while [ $count -le 1 ]
        do
            # make task
            task=$(curl -s -u $CREDS -H "Content-Type: Application/json" -H 'Expect:' -X POST http://localhost:8100$as3Url?async=true -d @/config/as3.json | jq -r .id)
            taskId=$(echo $task)
            echo "starting as3 task: $taskId"
            sleep 1
            count=$[$count+1]
            # check task code
        while true
        do
            status=$(restcurl -s -u $CREDS $as3TaskUrl/$taskId | jq ".items[] | select(.id | contains (\"$taskId\")) | .results")
            messages=$(echo "$status" | jq -r .[].message)
            tenants=$(echo "$status" | jq .[].tenant)
            case $messages in
            *Error*)
                # error
                echo -e "Error: $taskId status: $messages tenants: $tenants "
                break
                ;;
            *failed*)
                # failed
                echo -e "failed: $taskId status: $messages tenants: $tenants "
                break
                ;;
            *success*)
                # successful!
                echo -e "success: $taskId status: $messages tenants: $tenants "
                break 3
                ;;
            no*change)
                # finished
                echo -e "no change: $taskId status: $messages tenants: $tenants "
                break 3
                ;;
            in*progress)
                # in progress
                echo -e "Running: $taskId status: $messages tenants: $tenants "
                sleep 60
                ;;
            *)
            # other
            echo "status: $messages"
            debug=$(curl -s -u $CREDS http://localhost:8100/mgmt/shared/appsvcs/task/$taskId | jq .)
            echo "debug: $debug"
            error=$(curl -s -u $CREDS http://localhost:8100/mgmt/shared/appsvcs/task/$taskId | jq -r '.results[].message')
            echo "Other: $taskId, $error"
            ;;
            esac
        done
    done
}
#  run as3
count=0
while [ $count -le 4 ]
do
    as3Status=$(checkAS3)
    echo "AS3 check status: $as3Status"
    if [[ $as3Status == *"online"* ]]; then
        if [ "$deviceId" -eq 1 ]; then
            echo "running as3"
            runAS3
            echo "done with as3"
            results=$(restcurl -u $CREDS $as3TaskUrl | jq '.items[] | .id, .results')
            echo "as3 results: $results"
            break
        else
            echo "Not posting as3 device $deviceid not primary"
            break
        fi
    elif [ "$count" -le 2 ]; then
        echo "Status code: $as3Status  As3 not ready yet..."
        count=$[$count+1]
    else
        echo "As3 API Status $as3Status"
        break
    fi
done
#
function installWebTop () {
    tmsh create apm profile connectivity /SRA/webtop_cp
    tmsh create apm profile vdi /SRA/webtop_vdi
    tmsh create ltm profile rewrite /SRA/webtop_rwp defaults-from rewrite-portal location-specific false split-tunneling false request { insert-xforwarded-for enabled rewrite-headers enabled } response { rewrite-content enabled rewrite-headers enabled }
    #import pre-fabricated template
    ng_import -s /config/webtop_psp.tgz webtop_ap -p SRA
    if [ "$?" -eq 0 ]; then
        tmsh modify apm resource portal-access /SRA/webtop_ap-WebSSH_F5VM01 { application-uri "http://${webssh_vip}:10022/ssh/host/${f5vm01_mgmt_ip}?port=22&header=CLASSIFIED&headerBackground=red" }
        tmsh modify apm resource portal-access /SRA/webtop_ap-WebSSH_F5VM02 { application-uri "http://${webssh_vip}:10022/ssh/host/${f5vm02_mgmt_ip}?port=22&header=CLASSIFIED&headerBackground=red" }
        tmsh modify apm profile access /SRA/webtop_ap-rdp_gateway_ap generation-action increment
        tmsh modify apm profile access /SRA/webtop_ap generation-action increment
        tmsh modify ltm virtual /SRA/Webtop/serviceMain profiles add {/SRA/webtop_ap} profiles add {/SRA/webtop_vdi} profiles add {/SRA/webtop_cp} profiles add {/SRA/webtop_rwp}
        tmsh modify ltm virtual /SRA/Webtop/serviceMain cmp-enabled no
        ldbutil --add --uname="${api_user}" --password="${api_pass}" --instance="/SRA/webtop_ap-webtop_db" --user_groups="administrators" --login_failures="3" --change_passwd="false" --locked_out="false" --first_name="Azure" --last_name="Ops" --email="${api_user}@${dns_domain}"
    else
        echo "WARN: APM Policy import failed";
        whoout=$(whoami)
        idout=$(id)
        echo "DEBUG: user=$USER, shell=$SHELL, home=$HOME, whoout=$whoout, id=$idout"
    fi
}
if [ "$deviceId" -eq 1 ]; then 
    echo "Installing APM WebTop"
    installWebTop
else
    echo "Not installing APM WebTop: $deviceId is not primary"
fi
