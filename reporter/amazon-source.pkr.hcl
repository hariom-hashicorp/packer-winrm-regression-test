source "amazon-ebs" "aws-default" {
  ami_name                = "Windows-${var.OS_Major}-DataCenter-${var.Flavor}-${var.Template_Date}"
  ami_virtualization_type = "hvm"
  communicator            = "winrm"
  force_deregister        = true
  force_delete_snapshot   = true
  iam_instance_profile    = var.AWS_Instance_Profile
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  instance_type = var.VM_Size
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    encrypted             = false
    # kms_key_id = var.AWS_KMS_Key_ID
    volume_size = var.VM_Disk_Size
  }
  region             = var.Region
  security_group_ids = var.AWS_Security_Groups
  source_ami_filter {
    filters = {
      name                = "TPM-Windows_Server-${var.OS_Major}-English-${var.Flavor}-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [var.Account]
  }
  subnet_id             = var.Subnet
  ssh_interface         = "private_ip"
  tags                  = merge(local.commonTags, { Name = "Windows-${var.OS_Major}-${var.Flavor}-${var.Template_Date}" })
  run_tags              = local.commonTags
  run_volume_tags       = local.commonTags
  user_data_file        = "./Packer/Files/Setup-AWSPackerBuild.txt"
  vpc_id                = var.VPC
  winrm_connect_timeout = "30s"
  winrm_insecure        = true
  winrm_no_proxy        = true
  winrm_port            = 5986
  winrm_use_ntlm        = true
  winrm_use_ssl         = true
  winrm_username        = "Administrator"
  assume_role {
    role_arn     = var.AWS_ROLE_ARN
    session_name = var.AWS_SESSION_NAME
    # 3 hours
    duration_seconds = 10800
  }
  aws_polling {
    # Try for 2.5 hours
    delay_seconds = 30
    max_attempts  = 300
  }
}
