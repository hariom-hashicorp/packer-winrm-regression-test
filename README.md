# WinRM 403 Forbidden Regression - packer-plugin-sdk 0.6.11

This repository reproduces the WinRM 403 Forbidden issue reported in [hashicorp/packer-plugin-sdk#374](https://github.com/hashicorp/packer-plugin-sdk/issues/374).

## Issue

After upgrading packer-plugin-azure from 2.6.3 → 2.6.4 (which pulls packer-plugin-sdk 0.6.11), WinRM connections fail with:

```
[ERROR] connection error: unknown error Post "https://<ip>:5986/wsman": Forbidden
```

## Root Cause

PR #354 introduced `winrm_connect_timeout` parameter with default value `0` seconds. This is passed to the WinRM HTTP client, which interprets `0` as "reject immediately" instead of "no timeout".

The `prepareWinRM()` function in `communicator/config.go` is missing a default check for `WinRMConnectTimeout`.

## Reproduction

### Failing Template (v0.6.11)

See `azure-broken.pkr.hcl` - This will fail with 403 Forbidden

### Working Template (Workaround)

See `azure-fixed.pkr.hcl` - This includes `winrm_connect_timeout = "30s"` workaround

## Requirements

- Packer v1.9.0+
- Azure CLI credentials configured
- packer-plugin-azure 2.6.4 (uses packer-plugin-sdk 0.6.11)

## To Reproduce

```bash
# This will FAIL with 403 Forbidden
packer init azure-broken.pkr.hcl
packer build azure-broken.pkr.hcl

# This will SUCCEED (with workaround)
packer init azure-fixed.pkr.hcl
packer build azure-fixed.pkr.hcl
```

## Fix

Add to `communicator/config.go` in `prepareWinRM()` function:

```go
if c.WinRMConnectTimeout == 0 {
    c.WinRMConnectTimeout = 30 * time.Second
}
```

## References

- Issue: https://github.com/hashicorp/packer-plugin-sdk/issues/374
- PR: https://github.com/hashicorp/packer-plugin-sdk/pull/354

## AWS Windows WinRM Test

Use [aws-winrm.pkr.hcl](./aws-winrm.pkr.hcl) to test WinRM on a temporary
Windows Server 2022 EC2 instance instead of Azure. The Azure templates are
unchanged by this addition.

This template pins Amazon plugin **1.8.3**, which uses Packer plugin SDK
**0.6.12**. It tests connectivity with the default connection timeout and
with an explicit `30s` timeout; it does **not** reproduce the exact SDK
0.6.11 regression. Neither variant is assumed to fail on this version.
The SDK version is recorded in the plugin's
[go.mod](https://github.com/hashicorp/packer-plugin-amazon/blob/v1.8.3/go.mod).

### Prerequisites

- Packer and AWS CLI installed.
- Valid AWS credentials configured locally (environment variables, a named
  profile, or AWS SSO). Temporary credentials require a session token.
  Do not put credentials in templates, Git, or chat.
- Permission to describe/select AMIs and networking, run/terminate EC2
  instances, create/delete temporary key pairs and security groups, authorize
  ingress, retrieve the Windows password, and tag resources. Account policies
  must also permit the encrypted EBS volume.
- A default VPC with a public subnet in the selected region, or an existing
  public subnet supplied with `-var 'subnet_id=subnet-...'`. The subnet needs
  an internet gateway route, available public IPv4 addresses, and network
  ACLs that allow HTTPS WinRM and its return traffic.

The defaults are `eu-north-1` and `t3.medium`. Windows EC2, EBS, and public
IPv4 charges apply; this is not guaranteed to be free-tier eligible.

### Run

First confirm authentication in the same terminal that will run Packer:

```bash
# If using a named profile:
export AWS_PROFILE=your-profile
# For SSO profiles, authenticate with: aws sso login --profile your-profile

aws sts get-caller-identity
packer init aws-winrm.pkr.hcl
packer validate aws-winrm.pkr.hcl

# Recommended first run: explicit 30-second connection timeout.
packer build -on-error=cleanup \
  -only='aws-winrm.amazon-ebs.explicit-timeout' aws-winrm.pkr.hcl

# Then compare with the default connection timeout.
packer build -on-error=cleanup \
  -only='aws-winrm.amazon-ebs.default-timeout' aws-winrm.pkr.hcl
```

If you use environment credentials rather than a profile, omit the
`AWS_PROFILE` export and refresh those credentials locally before running.
An `InvalidClientTokenId` error means authentication must be fixed first;
it is not a WinRM failure.

To change region or use an existing public subnet, pass the same variables
to both validation and build, for example:

```bash
packer validate -var 'region=us-west-2' \
  -var 'subnet_id=subnet-REPLACE-ME' aws-winrm.pkr.hcl
packer build -on-error=cleanup \
  -only='aws-winrm.amazon-ebs.explicit-timeout' \
  -var 'region=us-west-2' -var 'subnet_id=subnet-REPLACE-ME' aws-winrm.pkr.hcl
```

Always supply the template filename, not `.`: this repository also contains
Azure templates and may contain Azure-only automatic variable files.
Without `-only`, Packer runs both AWS variants and launches two instances.

### Success and cleanup

The bootstrap script
[aws-winrm-user-data.ps1](./scripts/aws-winrm-user-data.ps1) enables HTTPS
WinRM on port 5986. Packer uses NTLM with the AMI-generated Administrator
password, retrieved through its temporary EC2 key pair; no password is
hardcoded. Certificate verification is disabled only for this disposable
test's self-signed certificate. Unencrypted WinRM and Basic authentication
remain disabled. The temporary security group restricts ingress to the
Packer host's public IP, detected through `checkip.amazonaws.com`.

A successful remote PowerShell provisioner prints **`WINRM_TEST_PASSED`**.
The template sets `skip_create_ami = true`, so it creates no AMI or snapshot
artifact. Packer normally terminates the instance, deletes its root volume,
and removes its temporary key pair and security group after success or
handled errors.

After an interrupted run or cleanup error, inspect EC2 in the selected
region for instances tagged `Purpose=temporary-winrm-test`, attached
volumes, and temporary `packer` key pairs/security groups. Terminate/remove
only resources belonging to this test. Force-killing Packer or losing
credentials can prevent automatic cleanup.
