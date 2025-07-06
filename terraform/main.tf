provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-omri" {
  name     = "omri-resources"
  location = var.location
}

resource "azurerm_virtual_network" "vnet-omri" {
  name                = "omri-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-omri.name
}

resource "azurerm_subnet" "subnet-omri" {
  name                 = "omri-subnet"
  resource_group_name  = azurerm_resource_group.rg-omri.name
  virtual_network_name = azurerm_virtual_network.vnet-omri.name
  address_prefixes     = ["10.0.1.0/24"]
}

