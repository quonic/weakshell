<#
.Synopsis
   Stop My list of services from a csv file
.DESCRIPTION
   This will stop a list of services based on the inputed csv file.
   Check end of script for more info of what is required.
.EXAMPLE
   Stop-MyServices -File .\mylist.csv
.EXAMPLE
   Stop-MyServices -File .\mylist.csv -Time 20
.EXAMPLE
   Stop-MyServices .\mylist.csv 20
#>
function Stop-MyServices
{
    [CmdletBinding()]
    Param
    (
        # File import csv
        [Parameter(Mandatory=$true,
                   Position=0)]
        $File,

        # Sleep Time, defaults to 10 seconds
        [int]
        [Parameter(Mandatory=$false,
            Position=1)]
        $Time=10
    )

    Begin
    {
        if(-not (Test-Path $File)){
            Write-Error "File Not Found: $File"
            exit
        }
        $List = Import-Csv $File


    }
    Process
    {
                
        for($i=0;$i -lt $List.Length;$i++){
            $k = $List[$i].Server
            $List[$i].Services.Split(';') | ForEach-Object {
                (Get-Service -ComputerName $k -Name $_).Stop()
            }
            Start-Sleep -Seconds $Time
        }
    }
    End
    {
    }
}

<#
Example CSV to import

Server,Services,
Server1,Service1;Service2,
#>
