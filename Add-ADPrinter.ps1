<#
.Synopsis
   Add a printer from your print server in AD
.DESCRIPTION
   Specify the Name, Port, and Address. Port should be in the format of "IP_255.255.255.255" and Address should be in the format of "\\server\printer"
.EXAMPLE
   Add-ADPrinter "OfficeColor" "IP_127.0.0.1" "\\ad1\OfficeColor"
.EXAMPLE
   Add-ADPrinter -Name "OfficeColor" -Port "IP_127.0.0.1" -Address "\\ad1\OfficeColor"
#>
function Add-ADPrinter
{
    [CmdletBinding()]
    Param
    (
        # Name that the computer will name the printer as
        [Parameter(Mandatory=$true,
                   Position=0)]
        $Name,
        # The IP_255.255.255.255 that the printer will connect to
        [Parameter(Mandatory=$true,
                   Position=1)]
        $Port,
        # The address that the printer will get use from AD
        [Parameter(Mandatory=$true,
                   Position=2)]
        $Address,
        # The address that the printer will get use from AD
        [Parameter(Mandatory=$false,
                   Position=3)]
        $Computer="localhost"
    )

    Begin
    {
    }
    Process
    {
        $Computer | ForEach {
            #Remove Printer with the same name
            if($Name -eq (Get-Printer -Name $Name -ComputerName $Computer).Name){Remove-Printer -Name $Name -ComputerName $Computer}
            if($Port -eq (Get-Printer -Name $Port -ComputerName $Computer).Name){Remove-PrinterPort -Name $Port -ComputerName $Computer}

            Add-Printer -ConnectionName $Address -Name $Name -PortName $Port -ComputerName $Computer
        }
    }
    End
    {
    }
}
