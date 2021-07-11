output app_id {
   value = local.app_id
}

output "b_bigip_management_address" {
 # value = "https://${module.bigip.mgmtPublicIP}:8443"
    value = module.bigip[*].mgmtPublicIP
}

output "c_application_address" {
  description = "Public endpoint for load balancing external app"
  value       = "https://${aws_eip.nlb_pip.public_ip}"
}

output "d_consul_public_address" {
   value = "https://${aws_instance.consulvm.public_ip}:8443"
 }

output "e_alertForwarder_public_address" {
   value = "https://${aws_instance.consulvm.public_ip}:8000"
}

# BIG-IP Username
output admin_name {
  value = module.bigip.*.f5_username
}

# BIG-IP Password
output admin_password {
  value = module.bigip.*.bigip_password
}
