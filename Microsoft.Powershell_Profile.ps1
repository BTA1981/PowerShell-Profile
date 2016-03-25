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
 GCI $Profiledir -Recurse | Unblock-File -Whatif 
 If running Script from a file share or remote machine, please include UNC path to IE intranet settings like *.serverx.domain.local 

 @echo off
SET DIR=%~dp0%
@PowerShell -NoProfile -ExecutionPolicy unrestricted -Command "& '%DIR%setup.ps1' %*"
pause

#>
#---------------------------------------------------------[Initialisations]---------------------------------------------------
# Set Profile Directory
$ProfileDir = Split-Path $Profile -parent

# Unblock Windows Powershell profile in case they were downloaded
Get-Childitem $profiledir -Recurse -Force | Unblock-File

# Allow running of scripts
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force

#----------------------------------------------------------[Functions]----------------------------------------------------------

# Prompt: Set Windows Ttile to show current user, host, current line number and colour
$global:CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
function prompt {
    $host.ui.rawui.WindowTitle = $CurrentUser.Name + " " + $Host.Name + " " + $Host.Version + $host.UI.RawUI.CursorPosition.Y
    Write-Host ("PS " + $(get-location) +">") -nonewline -foregroundcolor White
    return " "
}

Function Set-Dir {
    if (Test-Path C:\Beheer){
    Write-Output ""
    Write-Output "Setting location to beheer folder.."
    Set-Location C:\Beheer | Out-Null
    } else {
        Set-Location C:\ | Out-Null
    }
}

Function Install-Choco {
    if (Test-Path ($env:ALLUSERSPROFILE + "\Chocolatey")) {
        Write-Host "Chocolatey package manager exists" -ForegroundColor DarkYellow
    } else {
        Write-Host "Chocolatey package manager does not exist..." -ForegroundColor Magenta
        Write-Host "Downloading and installing..." -ForegroundColor Magenta
        iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
        #.$profile # Reloads current PS profile
    }
}

Function Install-GIT {
    if (Test-Path ($env:ALLUSERSPROFILE + "\Chocolatey\lib\git")) {
        Write-Host "GIT Package already exists..." -ForegroundColor DarkYellow
    } 
	Else {
        Write-Host "GIT Package does not exist..." -ForegroundColor Magenta
        Write-Host "Downloading and installing..." -ForegroundColor Magenta
		Choco install GIT -params "/GitOnlyonPath /NoAutoCrlf" -y
    }
}


Function Install-PsGet { # Install PsGet if not available
    If (!(Get-Module PsGet)) {
        Write-Output "Downloading and installing PSGet module installer.."
       (new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | Invoke-Expression | Out-Null
    }
}

Function Install-PoSHGit {
    If (!(Get-Module Posh-Git)) { # Install PowerShell GIT integration module from PsGet
        install-module Posh-Git # PsGet cmdlet 
        Import-Module Posh-Git -Args $true 
    }
}


# Copy GIT config to default GIT config folder (%USERPROFILE/$HOME)
Function Get-GITconfig {
    If (Test-Path ($ENV:HOME + "\.gitconfig")) {
        Write-Output "Custom GIT config exists, no further action required!"
    }
    Else { 
        Write-Output "Custom GIT profile doesn't exists, copying config file..."
        Copy-Item -Path $(($ProfileDir + "\GIT\.gitconfig")) -Destination $ENV:HOME
    }
}

Function Start-SSHagent {
    If ((![bool](Get-Process SSH-Agent -EA SilentlyContinue))) { # If an SSH-Agent process is NOT running
        Write-Host "Starting SSH Agent" -Fore White 
        Start-SshAgent
    } Else { Write-Host "SSH Agent is already started" -Fore White }
}



<#
.SYNOPSIS
  Custom function for use in PS profile. 
    Get-MyCredential
    Usage:
    

    If a credential is stored in $CredPath, it will be used.
    If no credential is found, Export-Credential will start and offer to
    Store a credential at the location specified.
.PARAMETER $CredPath 
 Path and file name of file that containts encrypted credentials.
.OUTPUTS
  PScredential object with encrypted credentials
.NOTES
  Version:        1.0
  Author:         Bart Tacken
  Creation Date:  14-03-2016
  Purpose/Change: Initial script development
  Source: http://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx
.EXAMPLE
  Get-MyCredential -CredPath C:\temp\credentials.xml
#>
function Get-MyCredential {
    param(
        [string]$CredPath,
        [switch]$Help
    )
        # Check if the path is valid and points to a file. If not, 
        if (!(Test-Path -Path $CredPath -PathType Leaf)) {
            Write-Host "Path and/or file [$CredPath] does not exist!"
            $User = Read-Host "Please enter a username if you like to create one.." 
            Export-Credential -User $User -Path $CredPath
        }
        # Import credentials from XML
        $credXML = Import-Clixml $CredPath
    
        # Create PScredential Object
        $Credential = New-Object System.Management.Automation.PsCredential($credXML.UserName, $credXML.Password)
        
        #Exit scope but returns variable
        Return $Credential
}

<#
.SYNOPSIS
  Custom function for use in PS profile. 
  Exports Credentials to an XML file for unattended use.
  These credentials can only be used by the same account and on the same machine from where these where created.

  XML file can be used to provide credentials for services like Azure or O365:
  $o365cred = Get-MyCredential -CredPath "C:\temp\cred4.xml"
  Connect-MsOlService -Credential o365

.PARAMETER $User
  Full username (service account)
.PARAMETER $Path 
 Output path with file names attribute if required
.OUTPUTS
  XML file with encrypted password credentials
.NOTES
  Version:        1.0
  Author:         Bart Tacken
  Creation Date:  14-03-2016
  Purpose/Change: Initial script development
  Source: http://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx
.EXAMPLE
  Export-Credential -user "test.account@demo.nl" -path c:\temp\Credentials.xml
#>
Function Export-Credential(
    [string]$user,
    [string] $path) {

    #Ask for Password interactively and store in memory using encryption (only reversible by account that created encrypted string)
    $PassWord = Read-Host "Please enter password" -AsSecureString
    
    # Uncomment following for encryping a plaintext variable: 
    # $PassWord = "P@ssword"
    # $PassWord = $PassWord | ConvertTo-SecureString -AsPlainText -Force
    
    # Create PScredential Object for CMDlets that require "-Credential" parameter
    $Credential = New-Object System.Management.Automation.PsCredential($user, $Password)
    
    # Export encrypted contents into XML file for later use 
    $Credential | Export-Clixml $path
}

Write-Host 'Use CONNECT-EXONLINE and DISCONNECT-EXONLINE for managing your O365 sessions' -ForegroundColor Cyan
Write-Host 'Use Get-MyCredential and Export-Credential for managing your PS credentials' -ForegroundColor Cyan

#----------------------------------------------------------[User Interface Config]--------------------------------------------------
$Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black')
$Host.UI.RawUI.ForegroundColor = 'Green'
$Host.PrivateData.ErrorForegroundColor = 'Magenta'
$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
$Host.PrivateData.WarningForegroundColor = 'Yellow'
$Host.PrivateData.WarningBackgroundColor = $bckgrnd
$Host.PrivateData.DebugForegroundColor = 'Yellow'
$Host.PrivateData.DebugBackgroundColor = $bckgrnd
$Host.PrivateData.VerboseForegroundColor = 'Green'
$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
$Host.PrivateData.ProgressForegroundColor = 'Cyan'
$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
#Clear-Host

#----------------------------------------------------------[Actions]----------------------------------------------------------

Set-Dir
Install-Choco

# Disable global confirmation prompts
choco config set allowglobalconfirmation disabled | Out-Null
Prompt
Install-PSGet


#----------------------------------------------------------[GIT Config]----------------------------------------------------------

Install-GIT
Install-PoSHGit 
. ($ProfileDir + "\Modules\PoSH-GIT\profile.example.ps1") -force
Get-GITconfig
Start-SSHagent
SSH-Add ($ProfileDir + "\SSH\SSH_key") # Import private SSH key for sync with GitHub/BitBucket 
