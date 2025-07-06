output "load_balancer_public_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}

output "vm_private_ips" {
  value = [for nic in azurerm_network_interface.nic : nic.private_ip_address]
}