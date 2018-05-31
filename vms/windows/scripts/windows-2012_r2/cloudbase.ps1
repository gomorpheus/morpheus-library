
function Setup-Cloudbase {
	
	Write-Host "Downloading cloudbase-init"
	$progressPreference = 'silentlyContinue'
	Invoke-WebRequest -OutFile 'C:\Windows\Temp\cloudbaseinit.msi' 'https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi'

	Write-Host "Installing cloudbase-init"
	$p = Start-Process -Wait -PassThru -FilePath msiexec -ArgumentList "/i C:\Windows\Temp\cloudbaseinit.msi /qn /l*v C:\Windows\Temp\cloudbaseinit-log.txt"
	if ($p.ExitCode -ne 0) {
	    Write-Host "ERROR: problem installing cloudbase-init!"
	}

	Write-Host "Running SetSetupComplete"
	cmd.exe /c "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\SetSetupComplete.cmd"

}
