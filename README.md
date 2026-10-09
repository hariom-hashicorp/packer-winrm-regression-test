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
