<#
.Synopsis
   Return the Computer Name, Current Users logged in, IP Address, and Boot Up Time in an array
.DESCRIPTION
   Return the Computer Name, Current Users logged in, IP Address, and Boot Up Time in an array
.EXAMPLE
   Get-ComputerInfo "Server1"
.EXAMPLE
   Get-ComputerInfo $ArrayOfComputerNames
.EXAMPLE
   $ArrayOfComputerNames | Get-ComputerInfo
#>
function Get-ComputerInfo
{
    [CmdletBinding()]
    Param
    (
        # Target of the computer
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [alias("Computer")]
        [string]$Target=$env:COMPUTERNAME
    )

    Begin
    {
        $Data = New-Object System.Object
    }
    Process
    {
        $Target | ForEach-Object{
            $User = (Gwmi Win32_Computersystem -Comp "D020").UserName
            $IP = [System.Net.Dns]::GetHostAddresses($_).IPAddressToString
            $BootUpTime = ([System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem -computername $_).LastBootUpTime))
            Add-Member -InputObject $Data -Type NoteProperty -Name "Computer" -Value $_
            Add-Member -InputObject $Data -Type NoteProperty -Name "Current User" -Value $User
            Add-Member -InputObject $Data -Type NoteProperty -Name "IP Address" -Value $IP
            Add-Member -InputObject $Data -Type NoteProperty -Name "Boot Up Time" -Value $BootUpTime
            
        }
    }
    End
    {
        $Data
    }
}
