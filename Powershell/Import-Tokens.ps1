#Requires -Version 4
<#
.SYNOPSIS
  Import tokens from a csv file
.DESCRIPTION
  Import tokens from a csv file because I was tired of how crappy FortiNet can't write
  a half way decent import function into thier product.
.PARAMETER <Parameter_Name>
  <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None>
.NOTES
  Version:        1.0
  Author:         Jim Caten
  Creation Date:  4/1/2017
  Status:         Imcomplete
  Purpose/Change: Initial script development
.EXAMPLE
  <Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
#>

[CmdletBinding()]
#region ---------------------------------------------------------[Script Parameters]------------------------------------------------------
Param (
  $Server = "https://127.0.0.1"
)
#endregion

#region ------------------------------------------------------------[EventIDs]------------------------------------------------------------
<#
  EventID 0: Info, Starting
  EventID 1: Warn, Something happened unexpectedly, but it is being handled. <Details of what is happening>
  EventID 2: Error, Something happened unexpectedly, and can't be handled. <Details of what is happening>
  EventID 4: Fatal, Something happened and exiting. <Details of what is happening>

  EventID 100: Fatal, Failed to get tokens
  EventID 101: Fatal, Failed to connect to server
  EventID 101: Info, Completed Sucessfully
  EventID 102: Fatal, Failed to get tokens
#>
#endregion

#region ---------------------------------------------------------[Initialisations]--------------------------------------------------------
$ErrorActionPreference = 'SilentlyContinue'

# Trust all certs as we don't use an internal CA
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#endregion

#region ----------------------------------------------------------[Declarations]----------------------------------------------------------
$ScriptName = "Import-Token"
#endregion

#region -----------------------------------------------------------[Functions]------------------------------------------------------------

function Get-Token {
    Params($Server,$Resource,$Credentials)
    $returnedData = Invoke-RestMethod -Method Get -Uri "$Resource/fortitokens/" -Credential $Credentials -Headers @{"Accept"="application/json"} -ErrorVariable $e
    if($e){
        Write-Log -Message "Exitting, error in getting tokens from $Server : $e" -EventID 102 -Level Fatal -Method Console
        Exit
    }
    $data = $returnedData.objects
    if($returnedData.meta){
        do{
            $returnedData = Invoke-RestMethod -Method Get -Uri "$($Server)$($returnedData.meta.next)" -Credential $Credentials -Headers @{"Accept"="application/json"} -ErrorVariable $e
            if($e){
                Write-Log -Message "Exitting, error in getting tokens from $Server : $e" -EventID 102 -Level Fatal -Method Console
                Exit
            }

            $data = $data + $returnedData.objects
        }while($returnedData.meta.next)
    
    }
    Write-Output $data
}

function Get-User {
    Params($Server,$Resource,$Credentials)
    $returnedData = Invoke-RestMethod -Method Get -Uri "$Resource/localusers/" -Credential $Credentials -Headers @{"Accept"="application/json"} -ErrorVariable $e
    if($e){
        Write-Log -Message "Exitting, error in getting users from $Server : $e" -EventID 100 -Level Fatal -Method Console
        Exit
    }
    $data = $returnedData.objects
    if($returnedData.meta){
        do{
            $returnedData = Invoke-RestMethod -Method Get -Uri "$($Server)$($returnedData.meta.next)" -Credential $Credentials -Headers @{"Accept"="application/json"} -ErrorVariable $e
            if($e){
                Write-Log -Message "Exitting, error in getting users from $Server : $e" -EventID 100 -Level Fatal -Method Console
                Exit
            }

            $data = $data + $returnedData.objects
        }while($returnedData.meta.next)
    
    }
    Write-Output $data
}
#endregion

#region --------------------------------------------------[Event Log Write-Log Function]--------------------------------------------------

Function Write-Log {
<#
.SYNOPSIS
    Standard Event Log entry writer
.DESCRIPTION
    Writes an entry to the local system's Event Log in a predictable and dependable way
.PARAMETER Level
    Sets the what type of entry this is.
.PARAMETER Message
    The information that you wish to convey in the Event Log
.PARAMETER EventID
    The Event ID of this log entry
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Version:        1.0
    Author:         Jim Caten
    Creation Date:  3/16/2017
    Purpose/Change: Initial Event Log Writer
.EXAMPLE
    Write-Log -Level Info -Message "Did task" -EventID 0
.EXAMPLE
    Write-Log -EntryType Info -Message "Did task" -EventID 0
#>
    Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Message,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateCount(0,65535)]
    [int]
    $EventID,
    [Parameter(Mandatory=$false)]
    [ValidateSet("Error", "Warn", "Info", "Fatal", "Debug", "Verbose")]
    [Alias("EntryType")]
    [string]
    $Level = "Info",
    [Parameter(Mandatory=$false)]
    [ValidateSet("EventLog", "Console", "LogFile")]
    [string]
    $Method = "EventLog",
    [Parameter(Mandatory=$false)]
    [string]
    $File
    )

    $Message = "{0}: {1}" -f $Level, $Message
    
    switch($Method){
        'EventLog' {
            switch($Level) {
                'Error'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType FailureAudit -EventId $EventID -Message $Message }
                'Warn'    { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Warning -EventId $EventID -Message $Message }
                'Info'    { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Information -EventId $EventID -Message $Message }
                'Fatal'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Error -EventId $EventID -Message $Message }
                'Debug'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Information -EventId $EventID -Message $Message }
                'Verbose' { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType SuccessAudit -EventId $EventID -Message $Message }
            }
        }
        'Console' {
            switch($Level) {
                'Error'   { Write-Error -Message "$Message" -ErrorId $EventID }
                'Warn'    { Write-Warning "Warning $EventID : $Message"}
                'Info'    { Write-Information "Warning $EventID : $Message" -ForegroundColor White}
                'Fatal'   { Write-Error -Message "$Message" -ErrorId $EventID}
                'Debug'   { Write-Debug -Message "$EventID : $Message"}
                'Verbose' { Write-Verbose "Warning $EventID : $Message"}
            }
        }
        'LogFile' {
            switch($Level) {
                'Error'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType FailureAudit -EventId $EventID -Message $Message }
                'Warn'    { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Warning -EventId $EventID -Message $Message }
                'Info'    { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Information -EventId $EventID -Message $Message }
                'Fatal'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Error -EventId $EventID -Message $Message }
                'Debug'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Information -EventId $EventID -Message $Message }
                'Verbose' { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType SuccessAudit -EventId $EventID -Message $Message }
            }
        }
    }
}
#endregion

#region -----------------------------------------------------------[Execution]------------------------------------------------------------

Begin {
    #initalizing variables and setting up things to be run, such as importing data or connecting to databases
    Write-Log -Message "Started..." -EventID 0
}
Process {


    $resource = "/api/v1/"
    
    # TODO: make this a Param such as $Credentials
    $Username = “admin”
    $Password = “zeyDZXmP6GbKcerqdWWEYNTnH2TaOCz5HTp2dAVS” # FortiAuth key for account that was emailed to you
    $secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($Username, $secpasswd)
    

    try{
        # Test if we can connect to the server
        Invoke-RestMethod -Method Get -Uri "$($Server)$($resource)" -Credential $mycreds -Headers @{"Accept"="application/json"}
    }catch{
        Write-Error -Exception "Server Not Found" -Message "Can not connect to server" -Category ConnectionError -ErrorId 101
        Exit
    }
    # Get all tokens from server
    $Tokens = Get-Tokens -Server $Server -Resource $resource -Credentials $mycreds
    # Get all users from server
    $Users = Get-User -Server $Server -Resource $resource -Credentials $mycreds
    # TODO: write Get-UserGroups function
    $ TODO: write New- functions, Update- maybe?
}
End {
    #clean up any variables, closing connection to databases, or exporting data
    If ($?) {
        Write-Log -Message 'Completed Successfully.' -EventID 101
    }
}
#endregion
