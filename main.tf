# Resource Group
resource "azurerm_resource_group" "avd_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Fetch tenant default domain for Entra ID user creation
data "azuread_domains" "default" {
  only_default = true
}

# Random password for sample account
resource "random_password" "sample_user_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*"
}

# Entra ID (Azure AD) Sample Account
resource "azuread_user" "sample_user" {
  user_principal_name = "${var.sample_user_mail_nickname}@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = var.sample_user_display_name
  mail_nickname       = var.sample_user_mail_nickname
  password            = random_password.sample_user_password.result
}

# AVD Host Pool
resource "azurerm_virtual_desktop_host_pool" "avd_hp" {
  name                     = var.host_pool_name
  location                 = azurerm_resource_group.avd_rg.location
  resource_group_name      = azurerm_resource_group.avd_rg.name
  type                     = "Pooled"
  load_balancer_type       = "BreadthFirst"
  maximum_sessions_allowed = 16
  preferred_app_group_type = "Desktop"
  custom_rdp_properties    = "targetisaad:i:1;enablerdsaadauth:i:1"
}

# AVD Application Group (Desktop)
resource "azurerm_virtual_desktop_application_group" "avd_dag" {
  name                = var.app_group_name
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd_hp.id
}

# AVD Workspace
resource "azurerm_virtual_desktop_workspace" "avd_ws" {
  name                = var.workspace_name
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  friendly_name       = "AVD Workspace Demo"
  description         = "Workspace for AVD hostpool deployment"
}

# Workspace <-> Application Group Association
resource "azurerm_virtual_desktop_workspace_application_group_association" "avd_ws_dag_assoc" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd_ws.id
  application_group_id = azurerm_virtual_desktop_application_group.avd_dag.id
}

# Role Assignment: Desktop Virtualization User for Sample Entra ID Account
resource "azurerm_role_assignment" "avd_user_role" {
  scope                = azurerm_virtual_desktop_application_group.avd_dag.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = azuread_user.sample_user.object_id
}

# Role Assignment: Virtual Machine User Login for Sample Entra ID Account
resource "azurerm_role_assignment" "vm_user_login" {
  scope                = azurerm_resource_group.avd_rg.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = azuread_user.sample_user.object_id
}

# Fetch current logged in Azure user / Service Principal
data "azurerm_client_config" "current" {}

# Role Assignment: Desktop Virtualization User for Primary Admin Account
resource "azurerm_role_assignment" "admin_avd_user_role" {
  scope                = azurerm_virtual_desktop_application_group.avd_dag.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Role Assignment: Virtual Machine User Login for Primary Admin Account
resource "azurerm_role_assignment" "admin_vm_user_login" {
  scope                = azurerm_resource_group.avd_rg.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Network Infrastructure for Session Host
resource "azurerm_virtual_network" "avd_vnet" {
  name                = "vnet-avd-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_subnet" "avd_subnet" {
  name                 = "snet-avd-sessionhosts"
  resource_group_name  = azurerm_resource_group.avd_rg.name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "avd_nsg" {
  name                = "nsg-avd-demo"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_subnet_network_security_group_association" "avd_nsg_assoc" {
  subnet_id                 = azurerm_subnet.avd_subnet.id
  network_security_group_id = azurerm_network_security_group.avd_nsg.id
}

resource "azurerm_network_interface" "avd_vm_nic" {
  name                = "nic-avd-vm-0"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.avd_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Random password for Session Host Local Administrator
resource "random_password" "vm_admin_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*"
}

# Host Pool Registration Info
resource "azurerm_virtual_desktop_host_pool_registration_info" "registration_token" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd_hp.id
  expiration_date = timeadd(timestamp(), "48h")

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

# Session Host Virtual Machine (Windows 11 Enterprise Multi-Session)
resource "azurerm_windows_virtual_machine" "avd_vm" {
  name                = "vm-avd-sh-0"
  resource_group_name = azurerm_resource_group.avd_rg.name
  location            = azurerm_resource_group.avd_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.vm_admin_password.result
  network_interface_ids = [
    azurerm_network_interface.avd_vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-23h2-avd"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Entra ID Login Extension for VM
resource "azurerm_virtual_machine_extension" "aad_login" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

# AVD Agent DSC Extension to Register VM with Host Pool
resource "azurerm_virtual_machine_extension" "avd_agent" {
  name                       = "AVDHostPoolRegistration"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      hostPoolName = azurerm_virtual_desktop_host_pool.avd_hp.name
      aadJoin      = true
    }
  })

  protected_settings = jsonencode({
    properties = {
      registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.registration_token.token
    }
  })

  depends_on = [
    azurerm_virtual_machine_extension.aad_login,
    azurerm_virtual_desktop_host_pool_registration_info.registration_token
  ]
}
