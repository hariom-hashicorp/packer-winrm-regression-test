# Reporter-provided reproduction fragments

Source: https://github.com/hashicorp/packer-plugin-sdk/issues/374

The Amazon source block, plugin requirements, and user-data script were supplied by the reporter and are preserved without formatting or configuration changes. The `...` separators and surrounding prose are not HCL and were not included in the HCL files.

## Environment reported

- Region: `us-east-2`
- Windows Server 2022: `ami-017a2ee58c7d8ec88`
- Windows Server 2025: `ami-012e12c84e34c3bfb`
- Runner container: `debian:bookworm-slim`
- Connections use private IPs.
- Uppercase and lowercase proxy variables were reported as `http://:3128` (as shared; do not assume this is a usable proxy address).
- NO_PROXY contains internal addresses and `.azmk8s.io,.eks.amazonaws.com,.elb.amazonaws.com,127.0.0.1,localhost`.
- `winrm_no_proxy = true` and `winrm_connect_timeout = "30s"` are already enabled.
- With Amazon 1.8.3, the reporter still gets immediate Forbidden errors on each retry with the 30-second setting.

## Completeness and safety

These are fragments, not a runnable build. Variable declarations/values, `local.commonTags`, and a build block were not supplied. No Azure source template was supplied in this reply. Run from the repository root once the missing configuration is provided so the original user-data path resolves.

The source retains `force_deregister = true` and `force_delete_snapshot = true`. Review these before running: an existing AMI with the same name and associated snapshots may be deleted. Use isolated test resources and unique image names. Builds incur cloud costs.

No cloud build or validation has been run here. Do not commit credentials or populated variable files.
