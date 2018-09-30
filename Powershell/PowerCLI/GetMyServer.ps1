<# 
.NAME
    Get-MyServer
.SYNOPSIS
    Get a list of my servers
.DESCRIPTION
    This will get a list of servers from a list of server names, Hyper-V, VMware, AWS, or Proxmox
.OUTPUTS
    PSCustomObject

#>
function Get-MyServer {
    [CmdletBinding()]
    [Alias("MyServer")]

    [OutputType([PSCustomObject])]

    Param
    (
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [Alias("Name")]
        [ValidateNotNullorEmpty()]
        [String[]]
        $ComputerName = '*',
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]
        $Environment,
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]
        $Role
    )
    Begin {
        $Computers = Get-Content -Path "$env:TEMP\MyServerList.xml" | ConvertFrom-CliXml
        
    }
    Process {
        $Computers | Where-Object {
            $_.ComputerName -like $ComputerName -or
            $_.Role -like $Role -or
            $_.Environment -like $Environment
        }
    }
    End {

    }
}

<# 
.NAME
    Add-MyServerSource
.SYNOPSIS
    Adds sources from where to later pull lists of servers

#>
function Add-MyServerSource {
    [CmdletBinding()]


    [OutputType([PSCustomObject])]


    Param
    (
        [ValidateScript( {Test-Path $_; if ($Validate) {Get-Content -Path $_ | Test-MyServerConnection}})]
        [String]
        $File,
        [ValidateScript( {Test-Path $_; if ($Validate) {Get-Content -Path $_ | ConvertFrom-Csv | Test-MyServerConnection}})]
        [String]
        $CsvFile,
        [ValidateNotNullorEmpty()]
        [ValidateScript( {if ($Validate) {$_ | Test-MyServerConnection}})]
        [String[]]
        $ComputerName,
        [ValidateNotNullorEmpty()]
        [Parameter(ParameterSetName = "HyperV")]
        [ValidateScript( {if ($Validate) {$_ | Test-MyServerConnection}})]
        [String[]]
        $HyperVHostName,
        [ValidateNotNullorEmpty()]
        [Parameter(ParameterSetName = "VMWare")]
        [ValidateScript( {if ($Validate) {$_ | Test-MyServerConnection}})]
        [String[]]
        $VMwareHostName,
        [PSCredential]
        $Credential,
        [Switch]
        $Validate
    )
    Begin {
        $UsingCredsProvided = $false
        if ($Credential) {
            $UsingCredsProvided = $true
        }
        if ($File) {
            $FileContent = Get-Content -Path $File
        }
        if ($HyperVHostName) {
            Get-VMHost -ComputerName $HyperVHostName
        }
        if ($VMwareHostName) {
            Import-Module -Name PowerCLI
            if ($UsingCredsProvided) {
                $vmwareSplat = @{
                    Server          = $VMwareHostName
                    Credential      = $Credential
                    SaveCredentials = $true
                    AllLinked       = $true
                }
            }
            else {
                $vmwareSplat = @{
                    Server    = $VMwareHostName
                    AllLinked = $true
                }
            }
            Connect-VIServer @vmwareSplat
        }
        [PSCustomObject[]]$ServerList = @()
    }
    Process {
        if ($Validate -and (Test-MyServerConnection -ComputerName $ComputerName)) {
            $ServerList = + [PSCustomObject]@{
                ComputerName = $ComputerName
                Role         = "Unknown"
                Environment  = "Unknown"
            }
        }
        if ($VMwareHostName) {
            $VMWareGuests = Get-VM | Select-Object -Property Guest | Select-Object -Property HostName
        }
        if ($HyperVHostName) {
            $HyperVGuests = (Get-VM -ComputerName $HyperVHostName | Select-Object -ExpandProperty NetworkAdapters).ipaddresses[0] | ForEach-Object {([system.net.dns]::GetHostByAddress($_)).hostname }
        }
    }
    End {
        $FileContent | ForEach-Object {
            $ServerList = + [PSCustomObject]@{
                ComputerName = $_
                Role         = "Unknown"
                Environment  = "Unknown"
            }
        }
        if ($CsvFile) {
            $CsvList = Get-Content -Path $CsvFile | ConvertFrom-Csv | Select-Object -Property ComputerName, Role, Environment
            if ($Validate) {
                $ServerList = + $CsvList | Where-Object {Test-MyServerConnection -ComputerName $_}
            }
            else {
                $ServerList = + $CsvList
            }
            
        }
        if (-not $Validate) {
            $ComputerName | ForEach-Object {
                $ServerList = + [PSCustomObject]@{
                    ComputerName = $_
                    Role         = "Unknown"
                    Environment  = "Unknown"
                }
            }
        }
        $VMWareGuests | ForEach-Object {
            $ServerList = + [PSCustomObject]@{
                ComputerName = $_
                Role         = "Guest"
                Environment  = "VMWare"
            }
        }
        $HyperVGuests | ForEach-Object {
            $ServerList = + [PSCustomObject]@{
                ComputerName = $_
                Role         = "Guest"
                Environment  = "Hyper-V"
            }
        }
        if ($VMwareHostName) {
            Disconnect-VIServer @vmwareSplat
        }
        $ServerList | ConvertTo-CliXml | Out-File -FilePath $env:TEMP\MyServerList.xml
    }
}

function Test-MyServerConnection {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullorEmpty()]
        [string[]]
        $ComputerName,
        [switch]
        $Detailed
    )
    
    begin {
    }
    
    process {
        if ($Detailed) {
            $ComputerName | Test-NetConnection | Where-Object {$_.PingSucceeded -eq $false}
        }
        else {
            if (($ComputerName | Test-NetConnection | Where-Object {$_.PingSucceeded -eq $false}).Count -gt 0) {
                return $false
            }
            else {
                return $true
            }
        }
    }
    
    end {
    }
}
