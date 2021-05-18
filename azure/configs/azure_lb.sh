#!/bin/bash

az network lb create \
    --resource-group ${rg_name} \
    --name ${lb_name} \
    --sku Standard \
    --public-ip-address ${public_ip} \
    --public-ip-zone 1 \
    --backend-pool-name f5BackEndPool

az network lb probe create \
    --resource-group ${rg_name} \
    --lb-name ${lb_name} \
    --name f5HealthProbe \
    --protocol tcp \
    --port 443

az network lb rule create \
    --resource-group ${rg_name} \
    --lb-name ${lb_name} \
    --name f5HTTPSRule \
    --protocol tcp \
    --frontend-port 443 \
    --backend-port 443 \
    --backend-pool-name f5BackEndPool \
    --probe-name f5HealthProbe \
    --disable-outbound-snat true \
    --idle-timeout 15 \
    --enable-tcp-reset true

az network lb rule create \
    --resource-group ${rg_name} \
    --lb-name ${lb_name} \
    --name f5HTTPRule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port  80\
    --backend-pool-name f5BackEndPool \
    --probe-name f5HealthProbe \
    --disable-outbound-snat true \
    --idle-timeout 15 \
    --enable-tcp-reset true


