output mgmtPublicIP {
  description = "The actual ip address allocated for the resource."
  value       = data.azurerm_public_ip.f5vm01mgmtpip.ip_address
}

output mgmtPublicDNS {
  description = "fqdn to connect to the first vm provisioned."
  value       = data.azurerm_public_ip.f5vm01mgmtpip.fqdn
}


output mgmtPort {
  description = "Mgmt Port"
  value       = local.total_nics > 1 ? "443" : "8443"
}

output f5_username {
  value = var.f5_username
}

output bigip_password {
  value       = local.upass 
}

output onboard_do {
  value      = data.template_file.clustermemberDO1[0].rendered 
  depends_on = [data.template_file.clustermemberDO1[0]]

}

output mgmt_nic {
  value = azurerm_network_interface.mgmt_nic.*.id
}



