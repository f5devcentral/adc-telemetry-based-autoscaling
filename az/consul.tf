resource "azurerm_public_ip" "consulvmip" {
  name                = "${var.prefix}-consulvmip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"

  tags = {
    Name        = "${var.environment}-consulvm-public-ip"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}


resource "azurerm_network_interface" "consulvm-ext-nic" {
  name                      = "${var.prefix}-consulvm-ext-nic"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  //network_security_group_id = azurerm_network_security_group.main.id

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.Mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.consulvmext
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.consulvmip.id
  }

  tags = {
    Name        = "${var.environment}-consulvm-ext-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = "app1"
  }
}



resource "azurerm_virtual_machine" "consulvm" {
  name                = "consulvm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  network_interface_ids = [azurerm_network_interface.consulvm-ext-nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "consulvmOsDisk"
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
    computer_name  = "consulvm"
    admin_username = "azureuser"
    admin_password = var.upassword
    custom_data = file("consul.sh")

  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Name        = "${var.environment}-consulvm"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}
 