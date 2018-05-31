$WinlogonPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Remove-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon
Remove-ItemProperty -Path $WinlogonPath -Name DefaultUserName

. a:\bootstrap.ps1

Get-Boxstarter -Force

$secpasswd = ConvertTo-SecureString "m0rp#3us" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("morpheus", $secpasswd)

Import-Module $env:appdata\boxstarter\boxstarter.chocolatey\boxstarter.chocolatey.psd1
Install-BoxstarterPackage -PackageName a:\package.ps1 -Credential $cred
