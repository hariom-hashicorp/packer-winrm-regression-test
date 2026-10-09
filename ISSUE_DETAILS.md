# Issue Analysis: WinRM 403 Forbidden Regression

## GitHub Issue
- **#374:** https://github.com/hashicorp/packer-plugin-sdk/issues/374

## Affected Versions
- packer-plugin-sdk: 0.6.11
- packer-plugin-amazon: 1.8.3
- packer-plugin-azure: 2.6.4

## Last Working Version
- packer-plugin-sdk: 0.6.10
- packer-plugin-amazon: 1.8.2
- packer-plugin-azure: 2.6.3

## Error Message

```
[ERROR] connection error: unknown error Post "https://<ip>:5986/wsman": Forbidden
```

Occurs on every WinRM connection attempt and repeats until timeout.

## Root Cause Analysis

### PR #354
- **Commit:** `1e8582808f5f786f1abe69cbc112b75629298b3e`
- **Author:** @Pandapip1
- **Merged by:** @tanmay-hc
- **Date:** August 3, 2026

Introduced two new WinRM parameters:
1. `winrm_retry_interval` (default: `5s`) ✓ Has default check
2. `winrm_connect_timeout` (default: `0`) ✗ **NO default check**

### Missing Code

File: `communicator/config.go`
Function: `prepareWinRM()` (lines 634-658)

Current code sets defaults for:
- `WinRMPort` (line 635-638)
- `WinRMTimeout` (line 641-643)
- `WinRMRetryInterval` (line 645-647)

**Missing:**
```go
if c.WinRMConnectTimeout == 0 {
    c.WinRMConnectTimeout = 30 * time.Second
}
```

### Why `0` Causes 403 Forbidden

File: `sdk-internals/communicator/winrm/communicator.go` (line 39)

```go
endpoint := &winrm.Endpoint{
    Host:     config.Host,
    Port:     config.Port,
    HTTPS:    config.Https,
    Insecure: config.Insecure,
    Timeout:  config.ConnectTimeout,  // 0 gets passed here
}
```

When `Timeout` is `0`, the HTTP client interprets this as "reject immediately" instead of "no timeout", causing connections to be rejected with 403 Forbidden.

## Configuration Comparison

### Before (v0.6.10) - Works
```hcl
communicator        = "winrm"
winrm_use_ntlm       = true
winrm_use_ssl        = true
winrm_port           = 5986
winrm_insecure       = true
# No winrm_connect_timeout specified
# This didn't exist in 0.6.10
```

### After (v0.6.11) - Broken
```hcl
communicator        = "winrm"
winrm_use_ntlm       = true
winrm_use_ssl        = true
winrm_port           = 5986
winrm_insecure       = true
# winrm_connect_timeout defaults to 0
# HTTP client rejects connection immediately
```

### Workaround (v0.6.11)
```hcl
communicator        = "winrm"
winrm_use_ntlm       = true
winrm_use_ssl        = true
winrm_port           = 5986
winrm_insecure       = true
winrm_connect_timeout = "30s"  # Explicitly set
```

## Testing Scenarios

### Test 1: Default Behavior (No Timeout Specified)
- **Expected:** Connection succeeds
- **Actual (0.6.11):** 403 Forbidden
- **Status:** FAILS

### Test 2: With Workaround (Timeout = 30s)
- **Expected:** Connection succeeds
- **Actual:** Connection succeeds
- **Status:** PASSES

### Test 3: Explicit 0 Timeout
- **Expected:** Immediate rejection (by design)
- **Actual:** 403 Forbidden
- **Status:** Expected failure

## Files Involved

1. **communicator/config.go** (line 634-658)
   - Missing default check for `WinRMConnectTimeout`

2. **communicator/step_connect_winrm.go** (line 166)
   - Passes `WinRMConnectTimeout` to WinRM client

3. **sdk-internals/communicator/winrm/communicator.go** (line 39)
   - Sets HTTP client timeout to 0

## Recommended Fix

Add this code to `communicator/config.go` after line 647:

```go
if c.WinRMConnectTimeout == 0 {
    c.WinRMConnectTimeout = 30 * time.Second
}
```

This ensures:
- Backwards compatible (only sets if 0)
- Reasonable default (30s for most scenarios)
- Consistent with `WinRMRetryInterval` pattern
