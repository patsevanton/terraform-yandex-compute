<powershell>
net user Administrator "${windows_password}"
$chocoInstallScriptUrl  = 'https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'
$chocoInstallScript     = Join-Path $env:Temp 'SetupComplete.ps1'

Set-ExecutionPolicy Unrestricted

$downloader = New-Object System.Net.WebClient
$downloader.DownloadFile($chocoInstallScriptUrl, $chocoInstallScript)

& $chocoInstallScript
</powershell>
