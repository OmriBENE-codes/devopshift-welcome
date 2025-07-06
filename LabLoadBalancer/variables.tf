variable "location" {
  default = "East US"
}

variable "resource_group_name" {
  default = "rg-lb-demo"
}

variable "vnet_name" {
  default = "vnet-demo"
}

variable "subnet_name" {
  default = "subnet-demo"
}

variable "nsg_name" {
  default = "nsg-demo"
}

variable "vm_count" {
  default = 3
}

variable "admin_username" {
  default = "azureuser"
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  default = "Standard_B1s"
}

