#!/bin/bash

associateIP () {

     az network nic ip-config address-pool add \
     --address-pool f5BackendPool \
     --ip-config-name ${ip_config} \
     --nic-name ${nic_name} \
     --resource-group ${rg_name} \
     --lb-name ${lb_name}
}

associateIP

