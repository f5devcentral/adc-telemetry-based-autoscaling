output app_id {
   value = local.app_id
}

output "b_bigip_management_address" {
  value = "https://${module.bigip.0.mgmtPublicIP}:8443"
}

output "c_application_address" {
  description = "Public endpoint for load balancing external app"
  value       = "https://${azurerm_public_ip.nlb_public_ip.ip_address}"
}

output "d_consul_public_address" {
   value = "http://${azurerm_public_ip.consul_public_ip.ip_address}:8500"
 }

output "e_AlertForwarder_public_address" {
   value = "https://${azurerm_public_ip.af_public_ip.ip_address}:8000"
}