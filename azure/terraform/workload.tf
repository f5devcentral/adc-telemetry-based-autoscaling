#
# Create backend application workloads
#
resource "azurerm_network_interface" "appnic" {
 count               = var.workload_count
 name                = "app_nic_${count.index}"
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name

 ip_configuration {
   name                          = "testConfiguration"
   subnet_id                     = data.azurerm_subnet.mgmt.id
   private_ip_address_allocation = "dynamic"
 }
}

resource "azurerm_managed_disk" "appdisk" {
 count                = var.workload_count
 name                 = "datadisk_existing_${count.index}"
 location             = azurerm_resource_group.rg.location
 resource_group_name  = azurerm_resource_group.rg.name
 storage_account_type = "Standard_LRS"
 create_option        = "Empty"
 disk_size_gb         = "1023"
}

resource "azurerm_availability_set" "avset" {
 name                         = "avset"
 location                     = azurerm_resource_group.rg.location
 resource_group_name          = azurerm_resource_group.rg.name
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
}

data "template_file" "backendapp" {
  template          = file("../../templates/backendapp.tpl")
  vars = {
    app_id              = local.app_id
    consul_ip           = var.consul_ip
  }
}

resource "azurerm_virtual_machine" "app" {
 count                 = var.workload_count
 name                  = "app_vm_${count.index}"
 location              = azurerm_resource_group.rg.location
 availability_set_id   = azurerm_availability_set.avset.id
 resource_group_name   = azurerm_resource_group.rg.name
 network_interface_ids = [element(azurerm_network_interface.appnic.*.id, count.index)]
 vm_size               = "Standard_DS1_v2"


 # Uncomment this line to delete the OS disk automatically when deleting the VM
 delete_os_disk_on_termination = true

 # Uncomment this line to delete the data disks automatically when deleting the VM
 delete_data_disks_on_termination = true

 storage_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "18.04-LTS"
   version   = "latest"
 }

 storage_os_disk {
   name              = "myosdisk${count.index}"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 # Optional data disks
 storage_data_disk {
   name              = "datadisk_new_${count.index}"
   managed_disk_type = "Standard_LRS"
   create_option     = "Empty"
   lun               = 0
   disk_size_gb      = "1023"
 }

 storage_data_disk {
   name            = element(azurerm_managed_disk.appdisk.*.name, count.index)
   managed_disk_id = element(azurerm_managed_disk.appdisk.*.id, count.index)
   create_option   = "Attach"
   lun             = 1
   disk_size_gb    = element(azurerm_managed_disk.appdisk.*.disk_size_gb, count.index)
 }

 os_profile {
   computer_name  = format("workload-%s", count.index)
   admin_username = "appuser"
   admin_password = var.upassword
   custom_data    = data.template_file.backendapp.rendered
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

  tags = {
    Name                = "${var.environment}-backendapp_${count.index}"
    environment         = var.environment
    owner               = var.owner
    group               = var.group
    costcenter          = var.costcenter
    application         = var.application
    tag_name            = "Env"
    value               = "consul"
    propagate_at_launch = true
    key                 = "Env"
    value               = "consul"
  }
}
