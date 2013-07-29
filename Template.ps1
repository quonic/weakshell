<#
.SYNOPSIS
   Template
.DESCRIPTION
   Description of Template
.EXAMPLE
   Template.ps1
   Template.ps1 -Computer "Desktop1"
   Template.ps1 -Debug
#>

param (
    [string]$Computer = "localhost",
    [switch]$Debug = $true
)

$Location | ForEach {

    if($_ -eq "localhost")
        {
            #Do Nothing as we are localhost and probably running as a unprivilaged user.
        }else{
            Enter-PSSession $_
        }


    #Dubug
    if($Debug -eq $true)
        {
            "In Debug Mode"
        }
    #Enter Code Here

    if($_ -eq "localhost")
    {
        #Do Nothing as we are localhost and probably running as a unprivilaged user.
    }else{
        Exit-PSSession
    }

}
