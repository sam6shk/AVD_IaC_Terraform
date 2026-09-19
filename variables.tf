variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for AVD resources"
  default     = "rg-avd-demo"
}

variable "host_pool_name" {
  type        = string
  description = "Name of the AVD Host Pool"
  default     = "hp-avd-demo"
}

variable "workspace_name" {
  type        = string
  description = "Name of the AVD Workspace"
  default     = "ws-avd-demo"
}

variable "app_group_name" {
  type        = string
  description = "Name of the AVD Desktop Application Group"
  default     = "dag-avd-demo"
}

variable "sample_user_mail_nickname" {
  type        = string
  description = "Mail nickname for the sample Entra ID user account"
  default     = "avdsampleuser"
}

variable "sample_user_display_name" {
  type        = string
  description = "Display name for the sample Entra ID user account"
  default     = "AVD Sample User"
}

variable "vm_size" {
  type        = string
  description = "Size of the Session Host Virtual Machine"
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  type        = string
  description = "Local administrator username for Session Host VM"
  default     = "avdadmin"
}
