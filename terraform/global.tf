#define the provider and global variables
provider "azurerm" {
  features {}
}

variable "omri" {
  default = "omri"
  description = "omrib"
}

variable "vm_name" {
  default = "vm-omri"
  description = "vm-omrib"
}
variable "admin_username" {
  default     = "adminuser"
  description = "Username for the admin user on the VM"
}
variable "admin_password" {
  default     = "Password123!"
  description = "Password for the admin user on the VM"
}
variable "location" {
  default     = "East US"
  description = "Azure region where resources will be deployed"
}

variable "vm_size" {
  default     = "Standard_B1ms"
  description = "Size of the virtual machine"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-omri"
  location = var.location
}