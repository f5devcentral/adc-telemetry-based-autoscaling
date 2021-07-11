terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "4.9.4"  
    }
  }
}

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = var.github_owner
}

resource "github_repository_file" "adpm" {
  repository          = "adc-telemetry-based-autoscaling"
  branch              = "main"
  file                = "azure/consul_server.cfg"
  content             = format("https://%s:8443", azurerm_public_ip.consul_public_ip.ip_address)
  commit_message      = format("file contents update by application ID: %s", local.app_id)
  overwrite_on_create = true
}

provider azurerm {
    features {}
}

provider "consul" {
  address = "${azurerm_public_ip.consul_public_ip.ip_address}:8443"
  scheme  = "https" 
  insecure_https  = true
}

#
# Create a random id
#
resource random_id id {
  byte_length = 2
}

locals {
  # Ids for multiple sets of EC2 instances, merged together
  hostname          = format("bigip.azure.%s.com", local.app_id)
  event_timestamp   = formatdate("YYYY-MM-DD hh:mm:ss",timestamp())
  app_id            = random_id.id.hex
}

#
# Create a resource group
#
resource azurerm_resource_group rg {
  name     = format("adpm-%s-rg", local.app_id)
  location = var.location
}

#
# Create a load balancer resources for bigip(s) via azurecli
#
resource "azurerm_public_ip" "nlb_public_ip" {
  name                = format("application-%s-nlb-pip", local.app_id)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1]
}

resource "azurerm_lb" "nlb" {
  name                = format("application-%s-loadbalancer", local.app_id)  
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.nlb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "f5BackendPool" {
  loadbalancer_id = azurerm_lb.nlb.id
  resource_group_name = azurerm_resource_group.rg.name
  name            = "f5BackendPool"
}

resource "azurerm_lb_rule" "nlbrule1" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.nlb.id
  name                           = "NLBRule1"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.f5BackendPool.id
  probe_id                       = azurerm_lb_probe.lb_probe.id
}

resource "azurerm_lb_rule" "nlbrule2" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.nlb.id
  name                           = "NLBRule2"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PublicIPAddress"  
  backend_address_pool_id        = azurerm_lb_backend_address_pool.f5BackendPool.id
  probe_id                       = azurerm_lb_probe.lb_probe.id
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.nlb.id
  name                = "tcp-443-running-probe"
  port                = 443
}


#
#Create N-nic bigip
#
module bigip {
  count 		                = var.bigip_count
  source                    = "../f5module/"
  prefix                    = format("application-%s-1nic", var.prefix)
  resource_group_name       = azurerm_resource_group.rg.name
  mgmt_subnet_ids           = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" =  ""}]
  mgmt_securitygroup_ids    = [module.mgmt-network-security-group.network_security_group_id]
  availabilityZones         = var.availabilityZones
  app_name                  = var.app_name
  consul_ip                 = var.consul_ip
  app_id                    = local.app_id
  splunkIP                  = var.splunkIP
  splunkHEC                 = var.splunkHEC
  logStashIP                = var.logStashIP
  law_id                    = var.law_id
  law_primarykey            = var.law_primarykey
  ts_consumer               = var.ts_consumer
  backend_pool_id           = azurerm_lb_backend_address_pool.f5BackendPool.id

  providers = {
    consul = consul
  }

}

resource "null_resource" "clusterDO" {

  count = var.bigip_count

  provisioner "local-exec" {
    command = "cat > DO_1nic-instance${count.index}.json <<EOL\n ${module.bigip[count.index].onboard_do}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf DO_1nic-instance${count.index}.json"
  }
  depends_on = [ module.bigip.onboard_do]
}

#
# Create the Network Module to associate with BIGIP
#

module "network" {
  source              = "Azure/vnet/azurerm"
  vnet_name           = format("adpm-%s-vnet", local.app_id)
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.cidr]
  subnet_prefixes     = [cidrsubnet(var.cidr, 8, 1)]
  subnet_names        = ["mgmt-subnet"]
  depends_on = [
    azurerm_resource_group.rg,
  ]

  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}

data "azurerm_subnet" "mgmt" {
  name                 = "mgmt-subnet"
  virtual_network_name = module.network.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [module.network]
}

#
# Create the Network Security group Module to associate with BIGIP-Mgmt-Nic
#
module mgmt-network-security-group {
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("application-%s-mgmt-nsg", local.app_id )
  
  depends_on = [
    azurerm_resource_group.rg,
  ]
  
  tags = {
    environment = "dev"
    costcenter  = "terraform"
  }
}

#
# Create the Network Security group Module to associate with BIGIP-Mgmt-Nic
#

resource "azurerm_network_security_rule" "mgmt_allow_https" {
  name                        = "Allow_Https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  source_address_prefixes     = var.AllowedIPs
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("application-%s-mgmt-nsg", local.app_id)
  depends_on                  = [module.mgmt-network-security-group]
}
resource "azurerm_network_security_rule" "mgmt_allow_ssh" {
  name                        = "Allow_ssh"
  priority                    = 202
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  destination_address_prefix  = "*"
  source_address_prefixes     = var.AllowedIPs
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("application-%s-mgmt-nsg", local.app_id)
  depends_on                  = [module.mgmt-network-security-group]
}
resource "azurerm_network_security_rule" "mgmt_allow_https2" {
  name                        = "Allow_Https_8443"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8443"
  destination_address_prefix  = "*"
  source_address_prefixes     = var.AllowedIPs
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("application-%s-mgmt-nsg", local.app_id)
  depends_on                  = [module.mgmt-network-security-group]
}

resource "azurerm_network_security_rule" "mgmt_allow_alertforwarder" {
  name                        = "Allow_8000"
  priority                    = 204
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8000"
  destination_address_prefix  = "*"
  source_address_prefixes     = var.AllowedIPs
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("application-%s-mgmt-nsg", local.app_id)
  depends_on                  = [module.mgmt-network-security-group]
}

#
# Deploy Consul/alertForwarder Server
#
 resource "azurerm_public_ip" "consul_public_ip" {
  name                = "pip-mgmt-consul"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"   # Static is required due to the use of the Standard sku
  tags = {
    Name   = "pip-mgmt-consul"
    source = "terraform"
  }
}

resource "azurerm_network_interface" "consulvm-ext-nic" {
  name               = "${local.app_id}-consulvm-ext-nic"
  location           = var.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "primary"
    subnet_id                     =  data.azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.1.100"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.consul_public_ip.id
  }

  tags = {
    Name        = "${local.app_id}-consulvm-ext-int"
    application = "consulserver"
    tag_name    = "Env"
    value       = "consul"
  }
}

data "template_file" "consul" {
  template      = file("../../templates/consul.tpl")
  vars = {
    consul_ip       = var.consul_ip
    consul_ver      = "1.9.0"    
    github_token    = var.github_token
    repo_path       = var.repo_path
  }
}

resource "azurerm_virtual_machine" "consulvm" {
  name                  = "consulvm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.consulvm-ext-nic.id]
  vm_size               = "Standard_DS1_v2"
  
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true
  
  storage_os_disk {
    name              = "consulvmOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "consulvm"
    admin_username = "ubuntu"
    admin_password = var.upassword
    custom_data    = data.template_file.consul.rendered

  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Name                = "${local.app_id}-consulvm"
    tag_name            = "Env"
    application         = "consulserver"
    value               = "consul"
    propagate_at_launch = true
  }
}

data "azurerm_public_ip" "consul_public_ip" {
  name                = "pip-mgmt-consul"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_virtual_machine.consulvm
  ]
}

#
# Update consul server
#
resource "consul_keys" "app" {
  datacenter = "dc1"
  # Set the CNAME of our load balancer as a key
  key {
    path  = format("adpm/common/scaling/bigip/min")
    value = var.bigip_min
  }
  key {
    path  = format("adpm/common/scaling/bigip/max")
    value = var.bigip_max
  }
  key {
    path  = format("adpm/common/scaling/workload/min")
    value = var.workload_min
  }
  key {
    path  = format("adpm/common/scaling/workload/max")
    value = var.workload_max
  }
  key {
    path  = format("adpm/common/scaling/min_scaling_interval_seconds")
    value = var.scale_interval
  }
  key {
    path  = format("adpm/applications/%s/scaling/bigip/current_count", local.app_id)
    value = var.bigip_count
  }
  key {
    path  = format("adpm/applications/%s/scaling/workload/current_count", local.app_id)
    value = var.workload_count
  }
  key {
    path  = format("adpm/applications/%s/create_timestamp", local.app_id)
    value = local.event_timestamp
  }
  key {
    path  = format("adpm/applications/%s/scaling/bigip/last_modified_timestamp", local.app_id)
    value = local.event_timestamp
  }
  key {
    path  = format("adpm/applications/%s/scaling/workload/last_modified_timestamp", local.app_id)
    value = local.event_timestamp
  }
  key {
    path  = format("adpm/applications/%s/scaling/is_running", local.app_id)
    value = "false"
  } 
  key {
    path  = format("adpm/applications/%s/terraform/outputs/bigip_mgmt", local.app_id)
    value = "https://${module.bigip.0.mgmtPublicIP}:8443"
  }
  key {
    path  = format("adpm/applications/%s/terraform/outputs/application_address", local.app_id )
    value = "https://${azurerm_public_ip.nlb_public_ip.ip_address}"
  }
  key {
    path  = format("adpm/applications/%s/github_owner", local.app_id)
    value = var.github_owner
  }
  key {
    path  = format("adpm/applications/%s/repo_path", local.app_id)
    value = var.repo_path
  }
  key {
    path  = format("adpm/applications/%s/ts_consumer", local.app_id)
    value = var.ts_consumer
  }
  key {
    path  = format("adpm/applications/%s/splunkIP", local.app_id)
    value = var.splunkIP
  }
  key {
    path  = format("adpm/applications/%s/splunkHEC", local.app_id)
    value = var.splunkHEC
  }
  key {
     path  = format("adpm/applications/%s/logStashIP", local.app_id)
    value = var.logStashIP
  }
  key {
    path  = format("adpm/applications/%s/law_id", local.app_id)
    value = var.law_id
  }
  key {
    path  = format("adpm/applications/%s/law_primarykey", local.app_id)
    value = var.law_primarykey
  }
  key {
    path  = format("adpm/applications/%s/location", local.app_id )
    value = var.location
  }
}

data "template_file" "tfstate" {
  template          = file("../../templates/tfstate.tpl")
  vars = {
    app_id              = local.app_id
    consul_ip           = azurerm_public_ip.consul_public_ip.ip_address
  }
}

resource "local_file" "tfstate" {
  content  = data.template_file.tfstate.rendered
  filename = "tfstate.tf"
}