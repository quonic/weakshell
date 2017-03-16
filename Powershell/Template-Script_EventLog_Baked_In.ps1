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
#---------------------------------------------------------[Script Parameters]------------------------------------------------------
# https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.core/about/about_functions_advanced_parameters
Param (
  #Script parameters go here

)
#------------------------------------------------------------[EventIDs]------------------------------------------------------------
# Declare what Event IDs are used and their purpose
#  Example:
<#
  EventID 0: Info, Running tasks. <Details of what is happening>
  EventID 1: Warn, Something happened unexpectedly, but it is being handled. <Details of what is happening>
  EventID 2: Error, Something happened unexpectedly, and can't be handled. <Details of what is happening>
  EventID 4: Fatal, Something happened and exiting. <Details of what is happening>
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'SilentlyContinue'

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here
$ScriptName = "Template"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

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

#--------------------------------------------------[Event Log Write-Log Function]--------------------------------------------------
<#
.SYNOPSIS
  Writes entry to local system's Event Log
.DESCRIPTION
  Writes entry to local system's Event Log
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
  Author:         quonic/spyingwind
  Creation Date:  3/16/2017
  Purpose/Change: Initial Event Log Writer
.EXAMPLE
  Write-Log -Level Info -Message "Did task" -EventID 0
  
  Write-Log -EntryType Info -Message "Did task" -EventID 0
#>
Function Write-Log {
    Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Error", "Warn", "Info", "Fatal", "Debug", "Verbose")]
    [Alias("EntryType")]
    [string]
    $Level,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Message,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateCount(0,65535)]
    [int]
    $EventID
    )

    $Message = "{0}: {1}" -f $Level, $Message

    switch($Level) {
        'Error'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType FailureAudit -EventId $EventID -Message $Message }
        'Warn'    { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Warning -EventId $EventID -Message $Message }
        'Info'    { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Information -EventId $EventID -Message $Message }
        'Fatal'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Error -EventId $EventID -Message $Message }
        'Debug'   { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType Information -EventId $EventID -Message $Message }
        'Verbose' { Write-EventLog -LogName "Application" -Source $ScriptName -EntryType SuccessAudit -EventId $EventID -Message $Message }
    }
}
#-----------------------------------------------------------[Execution]------------------------------------------------------------


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
}
End {
    #clean up any variables, closing connection to databases, or exporting data
    If ($?) {
        Write-Log -Message 'Completed Successfully.' -EventID 100
    }
}
#>
