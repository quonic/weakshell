import-module ActiveDirectory
<#
.Synopsis
   Save Serial, Last Logged on user, and Model of the specified computer to Computer's Description field
.DESCRIPTION
   If ran with no arguments from ISE, or Powershell, it will load as a library.
   Otherwise it will run with defaults.

   Defaults:

   -EmailAddress will default to the username@yourdomain.com
      Please change the .com to your liking
   
   -Computer can be accepted from the pipe line or as a variable

   -Credential if set will prompt for your credentials and base the Domain\User off the running user's info

   -LogFile will save a ; delimited file to C:\Scripts\Logs\$env:computername.log unless otherwise specified.
      It will also create the folders if needed.

   -EmailAddress will send an email to the specifed address(es) from your smtp server.

   -EmailServer should be used if you want emails to send it
      Search this script for smtpserver and change the default if you don't want to have to specify it every time.

   Please modify as per to your enviroment.

.EXAMPLE
   Save-InfoToAD
.EXAMPLE
   Save-InfoToAD -Computer "Target-PC"
.EXAMPLE
   Save-InfoToAD -Computer "Target-PC" -LogFile "C:\temp\adlinfo.log"
.EXAMPLE
   Save-InfoToAD -Computer "Target-PC" -Credential
.EXAMPLE
   Save-InfoToAD -Computers "Target-PC" -EmailAddress "Test@test.com"
.EXAMPLE
   Save-InfoToAD -Computers "Target-PC" -EmailAddress "Test@test.com" -EmailServer "smtp.test.com"
.INPUTS
   -Computer -Credential -LogFile -EmailAddress -EmailServer
.NOTES
   Please modify as per to your enviroment.
#>
function Save-InfoToAD
{
    [CmdletBinding(DefaultParameterSetName='None', 
                  PositionalBinding=$false,
                  HelpUri = "https://github.com/quonic/weakshell/",
                  ConfirmImpact='Low')]
    Param
    (
        # Computer or list of computers by netbios name, dns name or ip
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   ParameterSetName='Computer')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Computer = $false,

        # Credential pass your Get-Credential variable if needed
        [Parameter(Mandatory=$false,
                   ParameterSetName='Credential')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Credential=$false,

        # LogFile defaults to C:\Scripts\Logs\$env:computername.log
        [Parameter(Mandatory=$false,
                   ParameterSetName='LogFile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $LogFile = "C:\Scripts\Logs\$env:computername.txt",

        # Email to Address or Addresses seperated by ;'s
        [Parameter(Mandatory=$false,
                   ParameterSetName='Email')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $EmailAddress = $env:username + "@" + $env:userdnsdomain,

        # Email to Address or Addresses seperated by ;'s
        [Parameter(Mandatory=$false,
                   ParameterSetName='Email')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $EmailServer = "mail.$env:userdnsdomain"
    )
    
    Begin
    {
        $ecode = 0
        $sub = "AD Update Log" # Mail Subject
        $body = "See attached" # Mail Body
        $from = "$credusername@$env:userdomain.com"
        
        # This is a great way to determin the SearchBase based on the User's DNS Domain, a.consto.com, b.a.consto.com, etc.
        $Domain = ""
        $i = 0
        $env:USERDNSDOMAIN.Split(".") | foreach {
            if($i -eq 0){$Domain = $Domain + "DC=" + $_}else{$Domain = $Domain + ",DC=" + $_}
            $i++}
        # Get the folder of the log and create the folder. Disregard if there is an error as the current user should have access.
        #  Shame on you for not reading the comments before running an untrusted script... :/
        $mkdirs = $LogFile.Substring(0,$LogFile.Length - $LogFile.split('\')[$LogFile.split('\').Count - 1].Length)
        mkdir $mkdirs -ErrorAction SilentlyContinue

        # remove our log file to update to latest.
        Clear-Content $LogFile -ErrorAction SilentlyContinue

        # Is a list already provided?
        if($Computer){}
        else
        {
            # Check if credentials need to be gathered and get a list of computer from AD
            if($Credential){
                $creds = Get-Credential -UserName "$env:userdomain\$env:username" -Message "Creds"
                $Computer = (Get-ADComputer -Filter {enabled -eq "true"} -SearchBase "ou=Workstations,$Domain" -Credential $Credential -Properties cn).cn
            }else{
                $Computer = (Get-ADComputer -Filter {enabled -eq "true"} -SearchBase "ou=Workstations,$Domain" -Properties cn).cn
            }
        }
        
        $dtime = Get-Date
        Add-content $LogFile -value "Type; Name; IP; Status; $dtime;"
        Write-Host "Type; Name; Status" -ForegroundColor Cyan
    }
    Process
    {
        #Test-Connection -Computer $Computer -BufferSize 16 -Count 1 -ea 0 -TimeToLive 32 | ForEach {
        ForEach ($comp in $Computer) {
            
                #Check if computer is windows or not and that we have access
                if(Test-Path "\\$comp\admin$\win.ini"){

                    # Call internal function
                    if($Credential){
                        Set-ADDescription -Computer $comp -LogFile $LogFile -Credential $Credential
                    }else{
                        Set-ADDescription -Computer $comp -LogFile $LogFile
                    }

                    
                }
            
            
        }
    }
    End
    {
        # Send email if told to
        if($EmailAddress){
            #check if we have creds and send email
            $body = $body + "`r`n" + ((Get-Content $LogFile) -split '["\n\r"|"\r\n"|\n|\r]')
            if($Credential){
                $credusername = $Credential.UserName
                Send-MailMessage -To $EmailAddress -From $from -Attachments $LogFile -Body $body -SmtpServer $EmailServer -Subject $sub -Credential $Credential
            }else{
                Send-MailMessage -To $EmailAddress -From $from -Attachments $LogFile -Body $body -SmtpServer $EmailServer -Subject $sub
            }
        }

        if ($ecode -gt 0){
            
            if($Host.Name -eq "Windows PowerShell ISE Host")
            {}else
            {
                exit 1775 # A null context handle was passed from the client to the host during a remote procedure call.
                #Close enough error to return in task scheduler, better than 0x0...
            }
        }
        exit 0
    }
}




function Set-ADDescription
{
Param
    (
        # Computer or list of computers by netbios name, dns name or ip
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Computer,

        # Credential pass your Get-Credential variable if needed
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Credential=$false,

        # LogFile defaults to C:\Scripts\Logs\$env:computername.log
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $LogFile = "C:\Scripts\Logs\$env:computername.log"
    )
    Try {
        #Check if we have creds
        if($Credential){
            #Get our info
            $name = get-wmiobject -ComputerName $Computer win32_OperatingSystem -Credential $Credential -ErrorAction stop
            $serial = Get-wmiobject -ComputerName $Computer win32_bios serialnumber -Credential $Credential -ErrorAction stop
            $model = Get-wmiobject -ComputerName $Computer Win32_ComputerSystem Model -Credential $Credential -ErrorAction stop
            $user = Get-WmiObject -ComputerName $Computer Win32_ComputerSystem UserName -Credential $Credential -ErrorAction stop

            #Combine our info for AD
            $desc = $user.UserName.Split("\")[1] + " - " + $model.Model + " - " + $serial.SerialNumber

            #Save to Description in AD
            Set-ADComputer $name.__SERVER -Description $desc -Credential $Credential
        }else{
            #Get our info
            $name = get-wmiobject -ComputerName $Computer win32_OperatingSystem -ErrorAction stop
            $serial = Get-wmiobject -ComputerName $Computer win32_bios serialnumber -ErrorAction stop
            $model = Get-wmiobject -ComputerName $Computer Win32_ComputerSystem Model -ErrorAction stop
            $user = Get-WmiObject -ComputerName $Computer Win32_ComputerSystem UserName -ErrorAction stop

            # Check that info is atleast not null...
            if($user.UserName -and $model.Model -and $serial.SerialNumber){
                #Combine our info for AD
                $desc = $user.UserName.Split("\")[1] + " - " + $model.Model + " - " + $serial.SerialNumber
                #Save to Description in AD
                Set-ADComputer $name.__SERVER -Description $desc
            }else{
                Add-content $LogFile -value "Error; $Computer; not giving info"
                Write-Host "Error; $Computer; not giving info"
                return
            }
            #Do some screen info of progress and save to log
            Add-content $LogFile -value "Computer; $comp; Saved;"
            Write-Host "Computer; $comp; Saved" -ForegroundColor Green
                        
        }
    } Catch {

        #Something went wrong, a mac or unix machine maybe
        $errj = $_.Exception.Message
        Add-content $LogFile -value "Error; $Computer; $errj;"
        Write-Host "Error; $Computer; $errj" -ForegroundColor Red
        $ecode = $ecode + 1

    } Finally {
        #cleanup
    }

}



if($Host.Name -eq "Windows PowerShell ISE Host")
{
    #In ISE or Running from console
    # Do nothing
    Write-Host "Run me Save-InfoToAD"
}else
{
    #We are being run in a script use defaults
    Save-InfoToAD
}

Export-ModuleMember -function Save-InfoToAD
