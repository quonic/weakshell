#Requires -Version 4
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
  <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None>
.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development
.EXAMPLE
  <Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
#>

[CmdletBinding()]
#[CmdletBinding(SupportsShouldProcess=$true)] # Use if you plan on accepting -whatif switch
#region ---------------------------------------------------------[Script Parameters]------------------------------------------------------
# https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.core/about/about_functions_advanced_parameters
Param (
  #Script parameters go here

)
#endregion

#region ------------------------------------------------------------[EventIDs]------------------------------------------------------------
# Declare what Event IDs are used, their purpose, and details on the reason for the log entry
#  Example:
<#
  EventID 0: Info, Running tasks. <Details of what is happening>
  EventID 1: Warn, Something happened unexpectedly, but it is being handled. <Details of what is happening>
  EventID 2: Error, Something happened unexpectedly, and can't be handled. <Details of what is happening>
  EventID 4: Fatal, Something happened and exiting. <Details of what is happening>
#>
#endregion

#region ---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins
#endregion

#region ----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here
$ScriptName = "Template"
#endregion

#region -----------------------------------------------------------[Functions]------------------------------------------------------------

<#
Function <FunctionName> {

  Param ()
  Begin {
    Write-Host '<description of what is going on>...'
  }
  Process {
    Try {
      <code goes here>
    }
    Catch {
      Write-Host -BackgroundColor Red "Error: $($_.Exception)"
      Break
    }
  }
  End {
    If ($?) {
      Write-Host 'Completed Successfully.'
      Write-Host ' '
    }
  }
}
#>
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

<# Template Code #>
<#
Begin {
    #initalizing variables and setting up things to be run, such as importing data or connecting to databases
    Write-Log -Message "Started..." -EventID 0
}
Process {
    Try {
        #code goes here
    }
    Catch {
        Write-Log -Message "Error: $($_.Exception)" -Level Error -EventID 2
        Break
    }
    if($pscmdlet.ShouldProcess("Target of action", "Action will happen")){
        #do action
    }else{
        #don't do action but describe what would have been done
    }
}
End {
    #clean up any variables, closing connection to databases, or exporting data
    If ($?) {
        Write-Log -Message 'Completed Successfully.' -EventID 100
    }
}
#>

#endregion
