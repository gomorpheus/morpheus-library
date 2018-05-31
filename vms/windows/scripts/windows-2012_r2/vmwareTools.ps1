cinst 7zip.commandline -y

if(Test-Path "C:\Windows\Temp\windows.iso") {
	Write-Host "Installing Guest Additions"
	7z x C:\Windows\Temp\windows.iso -oC:\Windows\Temp\Vmware
  Start-Process -FilePath "C:\Windows\Temp\Vmware\setup.exe" -ArgumentList "/S /v`"/qn REBOOT=R\`"" -WorkingDirectory "C:\Windows\Temp\Vmware" -Wait
  Remove-Item C:\Windows\Temp\Vmware -Recurse -Force
  Remove-Item C:\Windows\Temp\windows.iso -Force
}

exit 0
