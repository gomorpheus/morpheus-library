$ErrorActionPreference = "Stop"

. a:\testCommand.ps1

Write-Host "Enabling file sharing firewale rules"
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes

. a:\cloudbase.ps1
Write-Host "Installing cloudbase-init"
Setup-Cloudbase

#change cloudbase config
rename-item "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" cloudbase-init.bak
copy-item a:\cloudbase-init.conf "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" -Force

Write-Host "Cleaning SxS..."
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

@(
  "$env:localappdata\Nuget",
  "$env:localappdata\temp\*",
  "$env:windir\logs",
  "$env:windir\panther",
  "$env:windir\temp\*",
  "$env:windir\winsxs\manifestcache"
) | % {
  if(Test-Path $_) {
    Write-Host "Removing $_"
    try {
      Takeown /d Y /R /f $_
      Icacls $_ /GRANT:r administrators:F /T /c /q  2>&1 | Out-Null
      Remove-Item $_ -Recurse -Force | Out-Null 
    } catch { $global:error.RemoveAt(0) }
  }
}

Write-Host "defragging..."
if (Test-Command -cmdname 'Optimize-Volume') {
  Optimize-Volume -DriveLetter C
} else {
  Defrag.exe c: /H
}

Write-Host "0ing out empty space..."
$FilePath="c:\zero.tmp"
$Volume = Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'"
$ArraySize= 64kb
$SpaceToLeave= $Volume.Size * 0.05
$FileSize= $Volume.FreeSpace - $SpacetoLeave
$ZeroArray= new-object byte[]($ArraySize)
 
$Stream= [io.File]::OpenWrite($FilePath)
try {
  $CurFileSize = 0
  while($CurFileSize -lt $FileSize) {
    $Stream.Write($ZeroArray,0, $ZeroArray.Length)
    $CurFileSize +=$ZeroArray.Length
  }
}
finally {
  if($Stream) {
    $Stream.Close()
  }
}

Del $FilePath

mkdir C:\Windows\Panther\Unattend
copy-item a:\unattend.xml C:\Windows\Panther\Unattend\unattend.xml

Write-Host "Recreate pagefile after sysprep"
$System = GWMI Win32_ComputerSystem -EnableAllPrivileges
if ($system -ne $null) {
  $System.AutomaticManagedPagefile = $true
  $System.Put()
}

Write-Host "Preparing for sysprep"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -Value 00000000
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts" -ErrorAction Ignore
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -ErrorAction Ignore
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name "morpheus" -Value 00000000 -PropertyType "DWord" -ErrorAction Ignore

Write-Host "Reinstalling msdtc"
cmd.exe /c "msdtc -uninstall"
cmd.exe /c "msdtc -install"

Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status\SysprepStatus" -Name GeneralizationState -Value 7
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" -Name SkipRearm -Value 1

Write-Host "Running sysprep"
$p = Start-Process -Wait -PassThru -FilePath "$env:SystemRoot\System32\Sysprep\sysprep.exe" -ArgumentList "/quiet /generalize /oobe /shutdown /unattend:`"C:\Windows\Panther\Unattend\unattend.xml`""
if ($p.ExitCode -ne 0) {
  Write-Host "ERROR: problem running sysprep!"
}
Write-Host "sysprep complete"
