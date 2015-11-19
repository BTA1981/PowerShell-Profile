<#
    Function for safely importing modules:
    Check if module is already loaded.
    If not then load the module, otherwise write message that module is not available.
    
    Source:
    http://blogs.technet.com/b/heyscriptingguy/archive/2010/07/11/hey-scripting-guy-weekend-scripter-checking-for-module-dependencies-in-windows-powershell.aspx
#>

Function Import-ModuleSafe
{ 
    Param([string] $name) # 
    if ( -not ( Get-Module -name $name ) ) # Proceed if module is not already loaded
    {
        if ( Get-Module -ListAvailable | Where-Object { $_.name -eq $name } ) # If module is available then import
        {
            Import-Module -Name $name
            $true
        } # End If 
        else { 
            Write-Host "Module $name is not available!"
            $false
        } # Module not available 
    } # End If not module 
    else { $true } # Module already loaded 
} # End Function