# WinRM regression investigation

Tracks https://github.com/hashicorp/packer-plugin-sdk/issues/374.

## Reporter-provided configuration

See [reporter/README.md](reporter/README.md) for the Amazon configuration fragments and environment details, and [Packer/Files/Setup-AWSPackerBuild.txt](Packer/Files/Setup-AWSPackerBuild.txt) for the original user-data script.

These fragments are incomplete: variables, locals, and a build block must be supplied before running. No Azure source template was included in the reporter's reply.

## Correction to earlier analysis

The previous claim that a zero timeout means immediate rejection and causes HTTP 403 was incorrect. Go's HTTP client uses zero to mean no timeout; HTTP 403 does not establish a timeout failure. In SDK 0.6.10 the endpoint timeout was also implicitly zero.

The reporter confirms `winrm_connect_timeout = "30s"` still returns Forbidden. A nonzero timeout is therefore not a confirmed workaround, and PR #354 is not a confirmed root cause.

The existing `azure-broken.pkr.hcl` and `azure-fixed.pkr.hcl` files are untested generated drafts, not reporter-supplied or verified reproductions. Their names and comments must not be taken as evidence of failure or success. They also use an incorrect `terraform` header instead of Packer's `packer` header, and the `.tfvars` example is not automatically loaded by Packer.

## Next comparison

Compare Amazon 1.8.2 and 1.8.3 using the same image version, network, runner, and proxy environment. Investigate whether Forbidden originates from Windows or an HTTP proxy. Proxy involvement is a hypothesis, not a confirmed cause.

No builds have been executed by this assistant. Review destructive AMI options and cloud costs before testing.
