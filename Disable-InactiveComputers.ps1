Import-Module ActiveDirectory
<#
.Synopsis
   Query Active Directory, disable, and move the computer accounts which have not logged for the past 120 days
.DESCRIPTION
   This PowerShell Command will query Active Directory, disable, and move the computer accounts which have not logged for the past
   120 days.  You can easily change the number of days from 120 to any number of your choosing.  lastLogonDate is a Human
   Readable conversion of the lastLogonTimeStamp (as far as I am able to discern).
.EXAMPLE
   Disable-InactiveComputers
.EXAMPLE
   Disable-InactiveComputers -Domain "DC=consto,DC=com"
.EXAMPLE
   Disable-InactiveComputers -Domain "DC=consto,DC=com" -SearchBase "OU=Workstations"
.EXAMPLE
   Disable-InactiveComputers -Domain "DC=consto,DC=com" -SearchBase "OU=Workstations" -TargetPath "OU=Disabled,OU=Workstations"
.EXAMPLE
   Disable-InactiveComputers -Domain "DC=consto,DC=com" -SearchBase "OU=Workstations" -TargetPath "OU=Disabled,OU=Workstations" -Days "120"
#>
function Disable-InactiveComputers
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'https://github.com/quonic/weakshell/',
                  ConfirmImpact='Medium')]
    Param
    (
        # Your AD domain, defaults to "DC=" + ($env:USERDNSDOMAIN.Split(".") -join ",DC=")
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Domain="DC=" + ($env:USERDNSDOMAIN.Split(".") -join ",DC="),

        # The OU that you want to search, defaults to OU=Workstations
        [Parameter(Mandatory=$false)]        
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$true})]
        [string]
        $SearchBase="OU=Workstations",

        # Set Target path to move disabled computers to, defaults to OU=Disabled,OU=Workstations
        [Parameter(Mandatory=$false)]        
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$true})]
        [string]
        $TargetPath="OU=Disabled,OU=Workstations",
        
        # Set how many days back to not disable, defaults to 120
        [Parameter(Mandatory=$false)]        
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$true})]
        [string]
        $Days="120"
    )

    Begin
    {
        

        $then = (Get-Date).AddDays(-$Days) # The 120 is the number of days from today since the last logon.
        $getadcomps = Get-ADComputer -Property Name,lastLogonDate -Filter {(enabled -eq "true") -and (lastLogonDate -lt $then)} -SearchBase "$SearchBase,$Domain"
        if(!$getadcomps){
            Write-Warning "No inactive computers found."
            exit 0
        }
    }
    Process
    {
        $getadcomps | Move-ADObject -Targetpath "$TargetPath,$Domain"
        $getadcomps | Set-ADComputer -Enabled $false
    }
    End
    {
    }
}

if($Host.Name -eq "Windows PowerShell ISE Host")
{
    #In ISE or Running from console
    # Do nothing
    Write-Host "Run me Disable-InactiveComputers"
}else
{
    #We are being run in a script use defaults
    Disable-InactiveComputers
}

Export-ModuleMember -function Disable-InactiveComputers
