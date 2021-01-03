resource "azurerm_public_ip" "alertForwardervmip" {
  name                = "${var.prefix}-alertForwardervmip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"

  tags = {
    Name                = "${var.environment}-alertForwardervm-public-ip"
    environment         = var.environment
    owner               = var.owner
    group               = var.group
    costcenter          = var.costcenter
    application         = var.application
    tag_name            = "Env"
    value               = "alertForwarder"
    propagate_at_launch = true
  }
}
resource "azurerm_network_interface" "alertForwardervm-ext-nic" {
  name                = "${var.prefix}-alertForwardervm-ext-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.alertForwardervmext
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.alertForwardervmip.id
  }

  tags = {
    Name        = "${var.environment}-alertForwardervm-ext-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = "alertForwarderserver"
    tag_name    = "Env"
    value       = "alertForwarder"
  }
}


resource "azurerm_virtual_machine" "calertForwardervm" {
  name                = "alertForwardervm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  network_interface_ids = [azurerm_network_interface.alertForwardervm-ext-nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "alertForwardervmOsDisk"
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
    computer_name  = "alertForwardervm"
    admin_username = "ubuntu"
    admin_password = var.upassword
    custom_data    = file("alertForwarder.sh")

  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Name                = "${var.environment}-alertForwardervm"
    environment         = var.environment
    owner               = var.owner
    group               = var.group
    costcenter          = var.costcenter
    application         = var.application
    tag_name            = "Env"
    value               = "alertForwarder"
    propagate_at_launch = true
  }
}

# Associate network security groups with NICs
resource "azurerm_network_interface_security_group_association" "alertForwardervm-ext-nsg" {
  network_interface_id      = azurerm_network_interface.alertForwardervm-ext-nic.id
  network_security_group_id = azurerm_network_security_group.main.id
}