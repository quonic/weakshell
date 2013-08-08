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
                  HelpUri = 'http://mis.gemmy.com/',
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
        [Alias("Computers")] 
        $Computer,

        # Credential pass your Get-Credential variable if needed
        [Parameter(Mandatory=$false,
                   ParameterSetName='Credential')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Credential,

        # LogFile defaults to C:\Scripts\Logs\$env:computername.log
        [Parameter(Mandatory=$false,
                   ParameterSetName='LogFile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $LogFile,

        # Email to Address or Addresses seperated by ;'s
        [Parameter(Mandatory=$false,
                   ParameterSetName='Email')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $EmailAddress,

        # Email to Address or Addresses seperated by ;'s
        [Parameter(Mandatory=$false,
                   ParameterSetName='Email')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $EmailServer
    )
    
    Begin
    {
        # Change this to match your domain
        "You should change the needed configs in this script"
        pause
        exit
        
        
        $sBase = "ou=Workstations,DC=$env:userdomain,DC=com"
        $smtpserver = "mail.$env:userdomain.com"
        # check if LogFile is set
        if($LogFile){}
        else
        {
            # Make our dir
            mkdir "C:\Scripts\Logs\" -ErrorAction SilentlyContinue
            # Clear Logfile
            Clear-Content $LogFile -ErrorAction SilentlyContinue
            $LogFile = "C:\Scripts\Logs\$env:computername.log"
        }

        # Is a list already provided?
        if($Computer){}
        else
        {
            # Check if credentials need to be gathered and get a list of computer from AD
            if($Credential){
                $creds = Get-Credential -UserName "$env:userdomain\$env:username" -Message "Creds"
                $Computer = (Get-ADComputer -Filter {enabled -eq "true"} -SearchBase $sBase -Credential $Credential -Properties cn).cn
            }else{
                $Computer = (Get-ADComputer -Filter {enabled -eq "true"} -SearchBase $sBase -Properties cn).cn
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
            Try {
                #Check if we have creds
                if($Credential){
                    #Get our info
                    $name = get-wmiobject -ComputerName $comp win32_OperatingSystem -Credential $Credential -ErrorAction stop
                    $serial = Get-wmiobject -ComputerName $comp win32_bios serialnumber -Credential $Credential -ErrorAction stop
                    $model = Get-wmiobject -ComputerName $comp Win32_ComputerSystem Model -Credential $Credential -ErrorAction stop
                    $user = Get-WmiObject -ComputerName $comp Win32_ComputerSystem UserName -Credential $Credential -ErrorAction stop

                    #Combine our info for AD
                    $desc = $user.UserName.Split("\")[1] + " - " + $model.Model + " - " + $serial.SerialNumber

                    #Save to Description in AD
                    Set-ADComputer $name.__SERVER -Description $desc -Credential $Credential
                }else{
                    #Get our info
                    $name = get-wmiobject -ComputerName $comp win32_OperatingSystem -ErrorAction stop
                    $serial = Get-wmiobject -ComputerName $comp win32_bios serialnumber -ErrorAction stop
                    $model = Get-wmiobject -ComputerName $comp Win32_ComputerSystem Model -ErrorAction stop
                    $user = Get-WmiObject -ComputerName $comp Win32_ComputerSystem UserName -ErrorAction stop

                    #Combine our info for AD
                    $desc = $user.UserName.Split("\")[1] + " - " + $model.Model + " - " + $serial.SerialNumber

                    #Save to Description in AD
                    Set-ADComputer $name.__SERVER -Description $desc
                }
                #Do some screen info of progress and save to log
                Add-content $LogFile -value "Computer; $comp; Saved;"
                Write-Host "Computer; $comp; Saved" -ForegroundColor Green

            } Catch {

                #Something went wrong, a mac or unix machine maybe
                $errj = $_.Exception.Message
                Add-content $LogFile -value "Error; $comp; $errj;"
                Write-Host "Error; $comp; $errj" -ForegroundColor Red

            } Finally {
                #cleanup
            }
        }
    }
    End
    {
        # Send email if told to
        if($EmailAddress){
            $sub = "AD Update Log"
            $body = "See attached"
            
            if($EmailServer){
                $smtpserver = $EmailServer
            }

            #check if we have creds and send email
            if($Credential){
                $credusername = $Credential.UserName
                Send-MailMessage -To $EmailAddress -From "$credusername@$env:userdomain.com" -Attachments $LogFile -Body $body -SmtpServer $smtpserver -Subject $sub -Credential $Credential
            }else{
                Send-MailMessage -To $EmailAddress -From "$env:username@$env:userdomain.com" -Attachments $LogFile -Body $body -SmtpServer $smtpserver -Subject $sub
            }
        }
    }
}
