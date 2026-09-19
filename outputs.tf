output "resource_group_name" {
  description = "The name of the deployed resource group"
  value       = azurerm_resource_group.avd_rg.name
}

output "host_pool_id" {
  description = "The ID of the Azure Virtual Desktop Host Pool"
  value       = azurerm_virtual_desktop_host_pool.avd_hp.id
}

output "host_pool_name" {
  description = "The name of the Azure Virtual Desktop Host Pool"
  value       = azurerm_virtual_desktop_host_pool.avd_hp.name
}

output "workspace_id" {
  description = "The ID of the Azure Virtual Desktop Workspace"
  value       = azurerm_virtual_desktop_workspace.avd_ws.id
}

output "workspace_name" {
  description = "The name of the Azure Virtual Desktop Workspace"
  value       = azurerm_virtual_desktop_workspace.avd_ws.name
}

output "application_group_id" {
  description = "The ID of the Desktop Application Group"
  value       = azurerm_virtual_desktop_application_group.avd_dag.id
}

output "sample_user_principal_name" {
  description = "The User Principal Name of the sample Entra ID account"
  value       = azuread_user.sample_user.user_principal_name
}

output "sample_user_password" {
  description = "The generated password for the sample Entra ID account"
  value       = random_password.sample_user_password.result
  sensitive   = true
}

output "session_host_vm_name" {
  description = "Name of the deployed AVD Session Host VM"
  value       = azurerm_windows_virtual_machine.avd_vm.name
}

output "session_host_vm_private_ip" {
  description = "Private IP of the Session Host VM"
  value       = azurerm_network_interface.avd_vm_nic.private_ip_address
}
