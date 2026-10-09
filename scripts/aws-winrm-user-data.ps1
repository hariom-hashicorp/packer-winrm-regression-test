<powershell>
$ErrorActionPreference = 'Stop'

Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM
Enable-PSRemoting -SkipNetworkProfileCheck -Force

$certificate = New-SelfSignedCertificate `
    -DnsName $env:COMPUTERNAME `
    -CertStoreLocation Cert:\LocalMachine\My

New-Item -Path WSMan:\localhost\Listener `
    -Transport HTTPS `
    -Address '*' `
    -CertificateThumbPrint $certificate.Thumbprint `
    -Force

Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $false
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $false

New-NetFirewallRule `
    -DisplayName 'Packer WinRM HTTPS' `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 5986 `
    -Profile Any

Restart-Service -Name WinRM
</powershell>
