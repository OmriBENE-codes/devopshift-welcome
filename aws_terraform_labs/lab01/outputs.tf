output "vm_public_ip" {
  value       = aws_instance.vm.public_ip
  description = "Public IP address of the VM"
  depends_on  = [time_sleep.wait_for_ip]
}
output "vm_public_ip_check" {
  value      = aws_instance.vm.public_ip
  depends_on = [null_resource.check_public_ip]
  description = "Public IP address of the VM"
}