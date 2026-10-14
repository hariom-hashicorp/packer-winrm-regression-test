# Investigation status

Issue: https://github.com/hashicorp/packer-plugin-sdk/issues/374

The reporter observed WinRM Forbidden errors after upgrading Amazon 1.8.2 to 1.8.3 and Azure 2.6.3 to 2.6.4. SDK 0.6.11 is a suspected shared change, not a confirmed cause.

PR #354 added `winrm_connect_timeout` (documented default: zero/no per-attempt timeout) and `winrm_retry_interval` (default: five seconds between retries). The overall `winrm_timeout` remains 30 minutes by default.

Earlier documentation in this repository incorrectly asserted that zero means immediate rejection, claimed a 30-second timeout fixes the issue, and listed tests as passing/failing without executing them. Those claims are withdrawn. The reporter's supplied configuration already sets a 30-second connect timeout and still fails.

See `reporter/` and `Packer/Files/Setup-AWSPackerBuild.txt` for the supplied fragments. The private-IP and proxy environment should be retained when constructing a controlled reproduction. Check where the Forbidden response originates before proposing a fix.

No validated root cause, successful workaround, or executed reproduction is recorded in this repository.
