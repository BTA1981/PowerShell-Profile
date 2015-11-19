<#
 Windows PowerShell profile script
 Put this somewhere Windows expects it, e.g. at the path returned by this command: 
 > echo $profile
 
 In order to get PowerShell use it, you may need to set the execution policy.
 To allow local and remote-signed scripts, run (as administrator) this command:
 
 > Set-ExecutionPolicy RemoteSigned

 GIT Integration:
 GIT Source control comes in very handy for replicating scripts to servers and managing versions and branches.

 First download and install GIT manually (preferable the portable version):
 http://git-scm.com/download/win

 Copy .gitconfig to root of profile directory for setting correct defaults
  
#>

cd c:\ # Set Location

$host.PrivateData.ErrorForegroundColor = 'Magenta' # Make error messages more readable

# Set Profile Directory
$ProfileDir = Split-Path $Profile -parent

# Start Modulescripts
. ($ProfileDir + "\Scripts\Import-ModuleSafe.ps1") -force
. ($ProfileDir + "\Scripts\GIT-Prompt.ps1") -force

If ( -not (Get-Module PsGet)) { # Install PsGet if not available
   (new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex
}

If ( -not (Import-ModuleSafe Posh-Git)) { # Install PowerShell GIT integration module from PsGet
    install-module Posh-Git -Force 
    Import-Module Posh-Git
}

If ((![bool](Get-Process SSH-Agent -EA SilentlyContinue))) { # If an SSH-Agent process is NOT running
    Write-Host "Starting SSH Agent" -Fore White 
    Start-SshAgent
} Else { Write-Host "SSH Agent is already started" -Fore White }
# Add Git bin to PATH to access various GIT tools like SSH keygen
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"

If (Test-Path -Path ($Home + "\.gitconfig")) { # If there already is a GiT config file
    Write-Host "Git Config is already available" -Fore White }
Else { Write-Host "Copy custom Git config" -Fore White 
    Copy-Item -Path ($ProfileDir + "\GITconfig\.gitconfig") -Destination $home -Force
}

