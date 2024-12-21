#!/bin/bash

pub='f5-networks'
offer=`grep product terrafrom.tfvars |cut -d \" -f 2`
ver=`grep bigip_version terraform.tfvars |cut -d \" -f 2`

az login
az image terms accept --urn $pub:$offer:f5-big-best-plus-hourly-10gbps-po-0:$ver
