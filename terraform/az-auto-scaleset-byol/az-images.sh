#!/bin/bash

az login
az vm image list --publisher f5-networks --all > images.list

