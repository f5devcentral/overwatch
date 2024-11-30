#!/bin/bash

openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -days 365 \
  -nodes -keyout tls.key -out tls.crt -subj "/CN=*.f5demo.com" \
  -addext "subjectAltName=DNS:kibana.f5demo.com,DNS:grafana.f5demo.com"