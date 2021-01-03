# Outputs

output "Consul_Public_IP" { value = azurerm_public_ip.consulvmip.ip_address }
output "Access_Consul" { value = "http://${azurerm_public_ip.consulvmip.ip_address}:8500" }
output "ALB_app1_pip" { value = azurerm_public_ip.lbpip.ip_address }
output "HTTPS_Link" { value = "https://${azurerm_public_ip.lbpip.ip_address}" }
 