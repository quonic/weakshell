#
# What this does: 
#   Finds out if CryptoLocker has infected pc's on the network by looking for a registery in the HKEY_USER hive. Maybe able to use for terminal servers too.
#   If you find it:
#      Go to the machine and extract the registry [HKEY_CURRENT_USER\Software\CryptoLocker\Files]. This gives you a list of files that have been encrypted.
#      Use combo fix to clean it
#      Recover files that have been affected from backups.
#
# How to use this script:
#    Create a file called C:\listofcomputers.txt with a list of pc names
#    You need to be an administrator on the pc's
#    Remote Registry service needs to be running on the PC
# 
# Output:
#   Computer name, Status
#   Status Values
#         Null  - Machine is not available
#         True  - Machine has the register entry we are looking for
#         False - Changes are we are safe.
# 
#
# Tested on:
#    Windows 7
#

function Get-CryptoLocker
{
    [CmdletBinding()]
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
        $Computer = $false
    )

    Begin
    {
        $Type = [Microsoft.Win32.RegistryHive]::Users
        $Domain = ""
        $i = 0
        $env:USERDNSDOMAIN.Split(".") | foreach {
            if($i -eq 0){$Domain = $Domain + "DC=" + $_}else{$Domain = $Domain + ",DC=" + $_}
            $i++}
        if($Computer){}
        else
        {
            $Computer = (Get-ADComputer -Filter {enabled -eq "true"} -SearchBase "ou=Workstations,$Domain" -Properties cn).cn
        }
        $log = @{}
    }
    Process
    {
        #Test-Connection -Computer $Computer -BufferSize 16 -Count 1 -ea 0 -TimeToLive 32 | ForEach {
        ForEach ($comp in $Computer) {
            	$Status = $null  #if machine is not available
                #Check if computer is windows or not and that we have access
                if(Test-Path "\\$comp\admin$\win.ini"){

                    $Status = $false
		            $SubKeyNames = $null
		            $regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Type, $ComputerName)
		            $subKeys = $regKey.GetSubKeyNames() 

		            $subKeys | %{
			            $key = "$_\software"

			            Try
			            {
				            $regSubKey = $regKey.OpenSubKey($Key) 
				            $SubKeyNames = $regSubKey.GetSubKeyNames() 
				            if($SubKeyNames -match "CryptoLocker")
				            {
					            $Status = $true
				            }

			            }
			            Catch{}			
		            }
                    
                    $log.Add($ComputerName,$Stauts)
                }
            
            
        }
	    
	    return $log	 
    }
}

if($Host.Name -eq "Windows PowerShell ISE Host")
{
    #In ISE or Running from console
    # Do nothing
    "Type Get-CryptoLocker to run"
}else
{
    #We are being run in a script use defaults
    Get-CryptoLocker
}
