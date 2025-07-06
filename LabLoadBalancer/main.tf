provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-omri" {
  name     = "omri-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet-omri" {
  name                = "omri-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "East US"
  resource_group_name = azurerm_resource_group.rg-omri.name
}

resource "azurerm_subnet" "subnet-omri" {
  name                 = "omri-subnet"
  resource_group_name  = azurerm_resource_group.rg-omri.name
  virtual_network_name = azurerm_virtual_network.vnet-omri.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-omri"
  location            = azurerm_resource_group.rg-omri.location
  resource_group_name = azurerm_resource_group.rg-omri.name
}

# Network Security Rule to Allow SSH and HTTP
resource "azurerm_network_security_rule" "allow_http_ssh" {
  name                        = "allow-http-ssh-vm-omri"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "22"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-omri.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_lb" "lb" {
  name                = "lb-omri"
  location            = azurerm_resource_group.rg-omri.location
  resource_group_name = azurerm_resource_group.rg-omri.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_pool_association" {
  count                    = 2
  network_interface_id     = azurerm_network_interface.nic[count.index].id
  ip_configuration_name    = "internal-omri-${count.index + 1}"
  backend_address_pool_id  = azurerm_lb_backend_address_pool.lb_pool.id
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  count                    = 2
  network_interface_id     = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "http-probe-omri"
  protocol            = "Http"
  port                = 80
  request_path        = "/welcome.html"
  interval_in_seconds = 15
  number_of_probes    = 3
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "http-rule-omri"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
}

resource "azurerm_public_ip" "vm_pip" {
  count               = 2
  name                = "pip-omri-${count.index + 1}"
  location            = azurerm_resource_group.rg-omri.location
  resource_group_name = azurerm_resource_group.rg-omri.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "nic-omri-${count.index + 1}"
  location            = azurerm_resource_group.rg-omri.location
  resource_group_name = azurerm_resource_group.rg-omri.name

  ip_configuration {
    name                          = "internal-omri-${count.index + 1}"
    subnet_id                     = azurerm_subnet.subnet-omri.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = 2
  name                  = "omri-${count.index + 1}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg-omri.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = var.vm_size

  os_disk {
    name                 = "os-disk-omri-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false
  computer_name                   = "omri-${count.index + 1}"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [network_interface_ids]
  }

  depends_on = [azurerm_network_interface.nic, azurerm_public_ip.lb_pip]
}

# Null Resource for Apache Installation
resource "null_resource" "provision_apache" {
  count      = 2
  depends_on = [azurerm_linux_virtual_machine.vm]

  # Trigger to force rerun whenever timestamp changes
  triggers = {
    always_run = timestamp()
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2",
      "echo '<h1>Welcome to \"${azurerm_linux_virtual_machine.vm[count.index].computer_name}\" Web Server!</h1>' | sudo tee /var/www/html/welcome.html",
      "sudo systemctl start apache2",
      "sudo systemctl enable apache2"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = azurerm_public_ip.vm_pip[count.index].ip_address
      timeout  = "1m"
    }
  }
}

# Output for Load Balancer Public IP
output "load_balancer_ip" {
  value       = azurerm_public_ip.lb_pip.ip_address
  description = "The public IP address of the load balancer."
}

# Output the Server Information for Each VM
output "server_info" {
  value = [
    for i in range(2) : "Please browse: http://${azurerm_public_ip.lb_pip.ip_address}/welcome.html. Server: ${azurerm_linux_virtual_machine.vm[i].computer_name}"
  ]
  description = "Instructions to access the web server through the load balancer."
}