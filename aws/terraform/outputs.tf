output app_id {
   value = local.app_id
}

output "b_bigip_management_address" {
 # value = "https://${module.bigip.mgmtPublicIP}:8443"
    value = module.bigip[*].mgmtPublicIP
}

#output "c_application_address" {
#  description = "Public endpoint for load balancing external app"
#  value       = "https://${azurerm_public_ip.nlb_public_ip.ip_address}"
#}

output "d_consul_public_address" {
   value = "http://${aws_instance.consulvm.public_ip}:8500"
 }

output "e_alertForwarder_public_address" {
   value = "https://${aws_instance.alertforwardervm.public_ip}:8000"
}

# BIG-IP Username
output admin_name {
  value = module.bigip.*.f5_username
}

# BIG-IP Password
output admin_password {
  value = module.bigip.*.bigip_password
}
