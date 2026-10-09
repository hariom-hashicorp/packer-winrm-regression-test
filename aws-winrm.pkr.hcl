packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "= 1.8.3"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "subnet_id" {
  type    = string
  default = ""
}

source "amazon-ebs" "windows" {
  region        = var.region
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  ami_name        = "packer-winrm-test-${formatdate("YYYY-MM-DD-hhmmss", timestamp())}"
  skip_create_ami = true

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-*"
      architecture        = "x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  associate_public_ip_address               = true
  ssh_interface                             = "public_ip"
  temporary_security_group_source_public_ip = true
  user_data_file                            = "${path.root}/scripts/aws-winrm-user-data.ps1"

  communicator             = "winrm"
  winrm_username           = "Administrator"
  winrm_use_ntlm           = true
  winrm_use_ssl            = true
  winrm_insecure           = true
  winrm_port               = 5986
  winrm_timeout            = "15m"
  windows_password_timeout = "15m"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 40
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  run_tags = {
    Name    = "packer-winrm-test"
    Purpose = "temporary-winrm-test"
  }
}

build {
  name = "aws-winrm"

  source "source.amazon-ebs.windows" {
    name = "default-timeout"
  }

  source "source.amazon-ebs.windows" {
    name                  = "explicit-timeout"
    winrm_connect_timeout = "30s"
  }

  provisioner "powershell" {
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "$service = Get-Service WinRM",
      "if ($service.Status -ne 'Running') { throw 'WinRM service is not running' }",
      "$listener = Get-ChildItem WSMan:\\localhost\\Listener | Where-Object { $_.Keys -contains 'Transport=HTTPS' }",
      "if (-not $listener) { throw 'HTTPS WinRM listener is missing' }",
      "Write-Host ('WINRM_TEST_PASSED on ' + $env:COMPUTERNAME + ' as ' + [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    ]
  }
}
