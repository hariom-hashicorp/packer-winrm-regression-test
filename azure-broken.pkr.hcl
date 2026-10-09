packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "2.6.4"
    }
  }
}

source "azure-arm" "windows" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  managed_image_resource_group_name = var.resource_group
  managed_image_name                = "packer-windows-broken-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  os_type       = "Windows"
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2022-Datacenter"
  image_version   = "latest"

  location = var.location
  vm_size  = "Standard_D2s_v3"

  # WinRM Configuration - WITHOUT winrm_connect_timeout (will fail with 403 Forbidden)
  communicator        = "winrm"
  winrm_use_ntlm      = true
  winrm_use_ssl       = true
  winrm_port          = 5986
  winrm_insecure      = true
  # winrm_timeout       = "30m"

  # NOTE: Missing winrm_connect_timeout causes 403 Forbidden!
  # This is the bug in packer-plugin-sdk 0.6.11
}

build {
  name = "windows-broken"
  sources = [
    "source.azure-arm.windows"
  ]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Hello from Packer!'"
    ]
  }
}

variable "client_id" {
  type      = string
  sensitive = true
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "resource_group" {
  type = string
}

variable "location" {
  type = string
}
