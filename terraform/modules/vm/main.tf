
resource "azurerm_public_ip" "pip-omri" {
  name                = "omri-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-omri.name
  allocation_method   = "Dynamic"  # Dynamic IP allocation for Basic SKU
  sku = "Basic"  
}

resource "azurerm_network_interface" "nic-omri" {
  name                = "omri-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-omri.name

  ip_configuration {
    name                          = "omri-ipconfig"
    subnet_id                     = azurerm_subnet.subnet-omri.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-omri.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-omri" {
  name                  = "omri-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg-omri.name
  network_interface_ids = [azurerm_network_interface.nic-omri.id]
  size                  = var.vm_size

  os_disk {
    name              = "omri-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name = "omri-vm"
}
