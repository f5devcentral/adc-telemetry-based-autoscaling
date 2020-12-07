# Terraform Version Pinning
terraform {
  required_version = "~> 0.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.1.0"
    }
  }
}

# Create a Resource Group for the new Virtual Machine
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}_rg"
  location = var.location
}


# Create a Virtual Network within the Resource Group
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = [var.cidr]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Create the first Subnet within the Virtual Network
resource "azurerm_subnet" "Mgmt" {
  name                 = "Mgmt"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefix       = var.subnets["subnet1"]
}

# Create the second Subnet within the Virtual Network
resource "azurerm_subnet" "External" {
  name                 = "External"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefix       = var.subnets["subnet2"]
}
# Obtain Gateway IP for each Subnet
locals {
  depends_on = ["azurerm_subnet.Mgmt", "azurerm_subnet.External"]
  mgmt_gw    = cidrhost(azurerm_subnet.Mgmt.address_prefix, 1)
  ext_gw     = cidrhost(azurerm_subnet.External.address_prefix, 1)
}

# Create a Public IP for the Virtual Machines
resource "azurerm_public_ip" "vm01mgmtpip" {
  name                = "${var.prefix}-vm01-mgmt-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"

  tags = {
    Name        = "${var.environment}-vm01-mgmt-public-ip"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

resource "azurerm_public_ip" "backendip" {
  name                = "${var.prefix}-backendip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"

  tags = {
    Name        = "${var.environment}-backend-public-ip"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

# Create the first network interface card for Management 
resource "azurerm_network_interface" "vm01-mgmt-nic" {
  name                      = "${var.prefix}-vm01-mgmt-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
 // network_security_group_id = azurerm_network_security_group.main.id

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.Mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5vm01mgmt
    public_ip_address_id          = azurerm_public_ip.vm01mgmtpip.id
  }

  tags = {
    Name        = "${var.environment}-vm01-mgmt-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

 resource "azurerm_network_interface" "backend01-ext-nic" {
  name                      = "${var.prefix}-backend01-ext-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  //network_security_group_id = azurerm_network_security_group.main.id

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.backend01ext
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.backendip.id
  }

  tags = {
    Name        = "${var.environment}-backend01-ext-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = "app1"
  }
}
# Create the second network interface card for External
resource "azurerm_network_interface" "vm01-ext-nic" {
  name                      = "${var.prefix}-vm01-ext-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  //network_security_group_id = azurerm_network_security_group.main.id
 // depends_on                = [azurerm_lb_backend_address_pool.backend_pool]

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5vm01ext
    primary                       = true
  }

  ip_configuration {
    name                          = "secondary"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5vm01ext_sec
  }

  tags = {
    Name        = "${var.environment}-vm01-ext-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

 # Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = file("${path.module}/onboard.tpl")

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL        = var.AS3_URL
    libs_dir       = var.libs_dir
    onboard_log    = var.onboard_log
  }
}

data "template_file" "vm01_do_json" {
  template = file("${path.module}/cluster.json")

  vars = {
    host1          = var.host1_name
    local_host     = var.host1_name
    local_selfip   = var.f5vm01ext
    dns_server     = var.dns_server
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
  }
}
data "template_file" "as3_json" {
  template = file("${path.module}/as3.json")

  vars = {
    rg_name         = azurerm_resource_group.main.name
  }
}

# Create F5 BIGIP VMs
resource "azurerm_virtual_machine" "f5vm01" {
  name                         = "${var.prefix}-f5vm01"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  primary_network_interface_id = azurerm_network_interface.vm01-mgmt-nic.id
  network_interface_ids        = [azurerm_network_interface.vm01-mgmt-nic.id, azurerm_network_interface.vm01-ext-nic.id]
  vm_size                      = var.instance_type
  //availability_set_id          = azurerm_availability_set.avset.id

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "f5-networks"
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  storage_os_disk {
    name              = "${var.prefix}vm01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}vm01"
    admin_username = var.uname
    admin_password = var.upassword
    custom_data    = data.template_file.vm_onboard.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name      = var.image_name
    publisher = "f5-networks"
    product   = var.product
    }

  tags = {
    Name        = "${var.environment}-f5vm01"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

# backend VM
resource "azurerm_virtual_machine" "backendvm" {
  name                = "backendvm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  network_interface_ids = [azurerm_network_interface.backend01-ext-nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "backendOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "backend01"
    admin_username = "azureuser"
    admin_password = var.upassword
    custom_data    = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              docker run -d -p 80:80 --net=host --restart unless-stopped -e F5DEMO_APP=website -e F5DEMO_NODENAME='F5 Azure' -e F5DEMO_COLOR=ffd734 -e F5DEMO_NODENAME_SSL='F5 Azure (SSL)' -e F5DEMO_COLOR_SSL=a0bf37 chen23/f5-demo-app:ssl
EOF

  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Name        = "${var.environment}-backend01"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}
 