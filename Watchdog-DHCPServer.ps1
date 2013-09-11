<#

Notes from vocatus's batch file:

# Purpose:         DHCP server Watchdog & Failover script. Read notes below
# Requirements:    1. Domain administrator credentials & 'Logon as a batch job' rights
#                  2. Proper firewall configuration to allow connection
#                  3. Proper permissions on the DHCP backup directory
# Author:          vocatus on reddit.com/r/usefulscripts
#                  Spyingwind/Quonic Converted to Powershell
# Version:         1.2  + Added functionality to recover the DHCP database BACK to the primary server after a failure. Now when the backup server detects that
#                         the primary server has come back online after an outage, it will export its current copy of the DHCP database, upload it back to the 
#                         primary server, import it, and spin it back up using the most recent copy. This addresses the issue of new leases being passed out during
#                         an outage of the primary server and it not being aware of those leases when it comes back online.
#                       + Added 'REMOTE_OPERATIING_PATH' variable that lets us specify where the remote server keeps its DHCP working files during operation
#                       + Added 'UPDATED' variable to note when the script was last updated
#                  1.1c + Added quotes around all variables that could contain paths
#                       + Added full path to SC.exe to prevent failure in the event %PATH% gets corrupted or mangled (this happened in testing)
#                       * Fixed a glitch that could occur when pinging an assumed-down primary server that would incorrectly think it was back up
#                       - Removed almost every entry of '2>&1' since it's really not needed
#                  1.1b - Changed DATE to CUR_DATE format to be consistent with all other scripts
#                  1.1  - Comments improvement
#                       / Tuned some parameters (ping count on checking)
#                       / Some logging tweaks
#                       / Renamed FAILOVER_DELAY to FAILOVER_RECHECK_DELAY for clarity
#                  1.0d * Some logging tweaks
#                  1.0c * Some logging tweaks
#                  1.0 Initial write
# Notes:           I wrote this script after failing to find a satisfactory method of performing
#                  watchdog/failover between two Windows Server 2008 R2 DHCP servers.
#                 
# Use:             This script has two modes: 'Watchdog' and 'Failover.' 
#                  - Watchdog checks the status of the remote DHCP service, logs it, and then grabs the remote DHCP db backup file and imports it.
#                  - Failover mode is activated when the script cannot determine the status of the remote DHCP server. The script then activates 
#                    the local DHCP server with the latest backup copy it successfully retrieved from the primary server.
#                  
# Instructions: 
#                  1. Tune the variables in this script to your desired backup location and frequency
#                  2. On the primary server: set the DHCP backup interval to your desired backup frequency. The value is in minutes; I recommend 5 minutes.
#                     You do this by modifying this registry key: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DHCPServer\Parameters\BackupInterval
#                  3. On the backup server:  set this script to run as a scheduled task. I recommend every 10 minutes. 
# Notice: 
#                 !! Make sure to set it only to run if it isn't already running! If there is a failover you could have 
#                    Task Scheduler spawn a new instance of the script every n minutes and end up with hundreds of copies
#                    of this script running.

#>

Write-Output "Read script and check for any thing that might be destructive to your enviroment or any logic errors."
Write-Output "Exitting..."
# Read script and check for any thing that might be destructive to your enviroment.
exit 1

<#
.Synopsis
   DHCP server Watchdog & Failover script.
.DESCRIPTION
   Long description
#>
function Watchdog-DHCPServer
{
    [CmdletBinding()]
    Param
    (
        # Remote Name or IP address
        [Parameter(Mandatory=$true)]
        $Remote,

        # Backup Path, defaults to "Windows\system32\dhcp\backup"
        [Parameter(Mandatory=$false)]
        $Backup="Windows\system32\dhcp\backup",

        # Operating, defaults to "Windows\system32\dhcp"
        [Parameter(Mandatory=$false)]
        $Operating="Windows\system32\dhcp",

        # LocalBackup, defaults to "$env:SystemRoot\system32\dhcp"
        [Parameter(Mandatory=$false)]
        $LocalBackup="$env:SystemRoot\system32\dhcp",
        
        # RecheckDelay, defaults to 15
        [Parameter(Mandatory=$false)]
        $RecheckDelay=15,

        # LogPath Path to log file, defaults to "$env:SystemDrive\Log"
        [Parameter(Mandatory=$false)]
        $LogPath="$env:SystemDrive\Log",

        # LogFile File with out extention, defaults to "dhcpwatchdog"
        [Parameter(Mandatory=$false)]
        $LogFile="dhcpwatchdog",

        # LogMaxSize, defaults to 10485760
        [Parameter(Mandatory=$false)]
        $LogMaxSize=10485760

    )

    Begin
    {
        $Version="1.2"
        $Updated=2013-09-10
        $Title="DHCP Server Watchdog v$Version"
        $curdate=Get-Date
    
        # File check
        if(!(Test-Path $LogPath)){New-Item -ItemType directory -Path $LogPath}
        if(!(Test-Path $LogPath\$LogFile)){
            "--------------------------------------------" | Out-File -FilePath $LogPath\$LogFile.log -Append
            "Initializing new DHCP Server Watchdog log on $curdate, max log size $LogMaxSize bytes" | Out-File -FilePath $LogPath\$LogFile.log -Append
            "--------------------------------------------" | Out-File -FilePath $LogPath\$LogFile.log -Append
        }

        # Rotate logs
        if(!(Get-Item "$LogPath\$LogFile").Length -gt $LogMaxSize){
            if(!(Test-Path "$LogPath\$LogFile.4")){remove-item "$LogPath\$LogFile.4"}
            if(!(Test-Path "$LogPath\$LogFile.3")){move-item "$LogPath\$LogFile.3" "$LogPath\$LogFile.4"}
            if(!(Test-Path "$LogPath\$LogFile.2")){move-item "$LogPath\$LogFile.2" "$LogPath\$LogFile.3"}
            if(!(Test-Path "$LogPath\$LogFile.1")){move-item "$LogPath\$LogFile.1" "$LogPath\$LogFile.2"}
            if(!(Test-Path "$LogPath\$LogFile.log")){move-item "$LogPath\$LogFile" "$LogPath\$LogFile.1"}
        }

        # Prep the current log
        $intro = "-------------------------------------------------------------------------------------
DHCP Server Watchdog v$Version, $(Get-Date)
Running as: $env:USERDOMAIN\$env:USERNAME on $env:COMPUTERNAME

Job Options
Log location:            $LogPath\$LogFile.log
Log max size:            $LogMaxSize bytes
Watching primary server: $Remote
Mirroring this DHCP db:  $Backup
Local backup location:   $LocalBackup
-------------------------------------------------------------------------------------
$(Get-Date)         Starting Watchdog mode.

DHCP Server Watchdog v$Version
Running as: $env:USERDOMAIN\$env:USERNAME on $env:COMPUTERNAME
Log:        $LogPath\$LogFile.log"

        $intro | Out-File -FilePath $LogPath\$LogFile.log -Append


        $pingstatus = (Test-Connection -ComputerName $Remote -Count 5 -Quiet)
        $dhcpstatus = (if((Get-Service -ComputerName $Remote -Name Dhcpserver -ErrorAction SilentlyContinue | Where-Object {$_.status -eq "running"})){$true}else{$false})

        # I don't think this is needed...
        Write-Output "$(Get-Date)Verifying proper operation of DHCP server on $Remote, please wait..."
        Write-Output "$(Get-Date)Pinging $Remote..."  | Out-File -FilePath $LogPath\$LogFile.log -Append
        Write-Output "$(Get-Date)Pinging $Remote..."

        if($pingstatus){
            Write-Output "$(Get-Date) SUCCESS $Remote responded to ping." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date) SUCCESS $Remote responded to ping."
        }else{
            Write-Output "$(Get-Date) WARNING $Remote failed to respond to ping." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date) WARNING $Remote failed to respond to ping."
        }

        Write-Output "$(Get-Date)Checking DHCP server status on $Remote..." | Out-File -FilePath $LogPath\$LogFile.log -Append
        Write-Output "$(Get-Date)Checking DHCP server status on $Remote..."

        <# Another way to get a list of DHCP server, sometimes it is not correct. :/
         # Not used
        $Domain = "";$i = 0;$env:USERDNSDOMAIN.Split(".") | foreach {if($i -eq 0){$Domain = $Domain + "DC=" + $_}else{$Domain = $Domain + ",DC=" + $_}$i++}
        $dhcpserver = Get-ADObject -SearchBase "cn=configuration,$Domain" -Filter "objectclass -eq 'dhcpclass' -AND Name -ne 'dhcproot'" | select name | Where-Object -Match -Property "name" -Value $Remote
        #>

        if($dhcpstatus){
            # It's up and running do our backup :happydance:
            Write-Output "$(Get-Date) SUCCESS The DHCP service is running on $Remote." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date) SUCCESS The DHCP service is running on $Remote."

            # Proceeding with backup
            Write-Output "$(Get-Date)         Fetching DHCP database backup from $Remote..." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Fetching DHCP database backup from $Remote..."
            $proc=[System.Diagnostics.Process]::Start( "xcopy '\\$Remote\c$\$Backup\*' '$LocalBackup\backup_new_pending\' /E /Y /Q >NUL")
            if($proc.ExitCode -eq 0){
                Write-Output "$(Get-Date) SUCCESS Backup fetched from $Remote." | Out-File -FilePath $LogPath\$LogFile.log -Append
	            Write-Output "$(Get-Date) SUCCESS Backup fetched from $Remote."
	            Write-Output "$(Get-Date)         Rotating database backups..." | Out-File -FilePath $LogPath\$LogFile.log -Append
	            Write-Output "$(Get-Date)         Rotating database backups..."

	            # Rotate backups and use newest copy
	            if(!(Test-Path "$LocalBackup\backup5")){remove-item "$LocalBackup\backup5"}
                if(!(Test-Path "$LocalBackup\backup4")){move-item "$LocalBackup\backup4" "$LocalBackup\backup5"}
                if(!(Test-Path "$LocalBackup\backup3")){move-item "$LocalBackup\backup3" "$LocalBackup\backup4"}
                if(!(Test-Path "$LocalBackup\backup2")){move-item "$LocalBackup\backup2" "$LocalBackup\backup3"}
                if(!(Test-Path "$LocalBackup\backup1")){move-item "$LocalBackup\backup1" "$LocalBackup\backup2"}
                if(!(Test-Path "$LocalBackup\backup")){move-item "$LocalBackup\backup" "$LocalBackup\backup1"}
	            move-item "$LocalBackup\backup_new_pending" "$LocalBackup\backup"
	            Write-Output "$(Get-Date)         Database backups rotated." | Out-File -FilePath $LogPath\$LogFile.log -Append
	            Write-Output "$(Get-Date)         Database backups rotated."
            }else{
        	    Write-Output "$(Get-Date) WARNING There was an error copying the backup from $Remote." | Out-File -FilePath $LogPath\$LogFile.log -Append
	            Write-Output "$(Get-Date)         You may want to look into this since we were able to check the DHCPserver service status but the file copy failed." | Out-File -FilePath $LogPath\$LogFile.log -Append
	            Write-Output "$(Get-Date)         Skipping new database import due to copy failure." | Out-File -FilePath $LogPath\$LogFile.log -Append
	            Write-Output "$(Get-Date)         Job complete with errors." | Out-File -FilePath $LogPath\$LogFile.log -Append
	            Write-Output "$(Get-Date) WARNING There was an error copying the backup from $Remote."
	            Write-Output "$(Get-Date)         You may want to look into this since we were able to check the DHCPserver service status but the file copy failed."
	            Write-Output "$(Get-Date)         Skipping new database import due to copy failure."
	            Write-Output "$(Get-Date)         Job complete with errors."
            }
            # Import database
            Write-Output "$(Get-Date)         Starting local DHCP server to import new database..." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Starting local DHCP server to import new database..."
	            Start-Service Dhcpserver
            Write-Output "$(Get-Date)         Local DHCP server running. Performing import..." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Local DHCP server running. Performing import..."
	            netsh dhcp server restore "$LocalBackup\backup"
            Write-Output "$(Get-Date)         Import complete." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Import complete."
            Write-Output "$(Get-Date)         Stopping local DHCP server..." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Stopping local DHCP server..."
	            Stop-Service Dhcpserver
            Write-Output "$(Get-Date)         Local DHCP server stopped." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Local DHCP server stopped."
            Write-Output "$(Get-Date) SUCCESS Job complete, DHCP database backed up and ready for use. Exiting." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date) SUCCESS Job complete, DHCP database backed up and ready for use. Exiting."
        }else{
            # Service ain't running, do our failover. :'(

            # Log this AND display to console
            Write-Output "$(Get-Date) WARNING Failover activated." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Starting local DHCP server using most recent successful backup..." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date) WARNING Could not contact primary DHCP server $Remote. Failover activated."
            Write-Output "$(Get-Date)         Starting local DHCP server using most recent successful backup..."
	            Start-Service Dhcpserver
            Write-Output "$(Get-Date)         Local DHCP server started." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Entering monitoring loop. Checking if $Remote is back up every $RecheckDelay seconds..." | Out-File -FilePath $LogPath\$LogFile.log -Append
            Write-Output "$(Get-Date)         Local DHCP server started."
            Write-Output "$(Get-Date)         Entering monitoring loop. Checking if $Remote is back up every $RecheckDelay seconds..."

            #failover_loop ---------------------
            # First we ping the server and loop

            while((Test-Connection -ComputerName $Remote -TimeToLive $RecheckDelay -Count 1 -Quiet) -eq $false){
	            Write-Output "$(Get-Date) FAILURE No ping response from $Remote. Waiting $RecheckDelay seconds to check again." | Out-File -FilePath $LogPath\$LogFile.log -Append
	            Write-Output "$(Get-Date) FAILURE No ping response from $Remote. Waiting $RecheckDelay seconds to check again."
	        }
            Write-Output "$(Get-Date) NOTICE  $Remote is responding to pings." | Out-File -FilePath $LogPath\$LogFile.log -Append
	        Write-Output "$(Get-Date) NOTICE  $Remote is responding to pings."
            
            if(Test-Connection -ComputerName $Remote -Count 5 -Quiet){
                while(!(if((Get-Service -ComputerName $Remote -Name Dhcpserver -ErrorAction SilentlyContinue | Where-Object {$_.status -eq "running"})){$true}else{$false})){
                    # If the host responds to pings but the DHCP service isn't running, this executes
                    Write-Out "$(Get-Date) FAILURE $Remote DHCP isn't responding (yet?). Will try again in $RecheckDelay seconds." | Out-File -FilePath $LogPath\$LogFile.log -Append
                    Write-Out "$(Get-Date) FAILURE $Remote DHCP isn't responding (yet?). Will try again in $RecheckDelay seconds."
                }

                #Ping works and the service is running
                Write-Output "$(Get-Date) SUCCESS The DHCP service is running on $Remote." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date) SUCCESS The DHCP service is running on $Remote."
				Write-Output "$(Get-Date)         Primary DHCP server $Remote is back up. Beginning recovery procedures..." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date)         Primary DHCP server $Remote is back up. Beginning recovery procedures..."
				
				# Back up the database that we've been running temporarily while the primary server was down
				Write-Output "$(Get-Date)         Exporting the current DHCP database..." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date)         Exporting the current DHCP database..."
				netsh dhcp server backup "$env:TEMP\DHCP-RECOVERY"
				
				# Stop our local server since we're done performing DHCP server duties
				Write-Output "$(Get-Date)         Stopping local DHCP server..." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date)         Stopping local DHCP server..."
				Stop-Service Dhcpserver
				
				# Send the database back to the primary server
				Write-Output "$(Get-Date)         Uploading current DHCP database to $Remote..." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date)         Uploading current DHCP database to $Remote..."
				xcopy "$env:TEMP\DHCP-RECOVERY\*" "\\$Remote\c$\$Operating\DHCP-RECOVERY\" /S /Y /Q 2>NUL

				# Import the current database on the primary server
				Write-Output "$(Get-Date)         Importing current DHCP database on $Remote..." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date)         Importing current DHCP database on $Remote..."
				netsh dhcp server \\$Remote restore "\\$Remote\c$\$Operating\DHCP-RECOVERY"
				# force a delay to let it stop
				Start-Sleep 4000
				
				# Spin the primary server back up. For some reason we have to run the command twice for it to actually start. Don't ask.
				Write-Output "$(Get-Date)         Restarting DHCP server on $Remote..." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date)         Restarting DHCP server on $Remote..."
				(get-service -ComputerName $Remote -Name Dhcpserver).Stop() 
                Start-Sleep 8000
				(get-service -ComputerName $Remote -Name Dhcpserver).Start()
                Start-Sleep 5000
                get-service -ComputerName $Remote -Name Dhcpserver
                Start-Sleep 8000
				(get-service -ComputerName $Remote -Name Dhcpserver).Start()
				
				# Check to make sure it's working
				Write-Output "$(Get-Date)         Verifying functionality on primary server..." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date)         Verifying functionality on primary server..."
				if((Get-Service -ComputerName $Remote -Name Dhcpserver -ErrorAction SilentlyContinue | Where-Object {$_.status -eq "running"})){
                    Write-Output "$(Get-Date) SUCCESS DHCP server on $Remote is up and running. Recovery complete." | Out-File -FilePath $LogPath\$LogFile.log -Append
                }else{
                    Write-Output "$(Get-Date) FAILURE DHCP server on $Remote is not running. You should investigate this manually." | Out-File -FilePath $LogPath\$LogFile.log -Append
                }

				# Clean up
                Remove-Item -Recurse $env:TEMP\DHCP-RECOVERY
				
				# Done.
				Write-Output "$(Get-Date)         Exiting." | Out-File -FilePath $LogPath\$LogFile.log -Append
				Write-Output "$(Get-Date)         Exiting."
				exit 0
            }else{# If no ping response, this section executes
                Write-Output "$(Get-Date)         Okay Something is wonky here, the $Remote server was pingable before and now it isn't" | Out-File -FilePath $LogPath\$LogFile.log -Append
                Write-Output "$(Get-Date)         Okay Something is wonky here, the $Remote server was pingable before and now it isn't"
                Write-Output "$(Get-Date)         Exitting to not screw up something." | Out-File -FilePath $LogPath\$LogFile.log -Append
                Write-Output "$(Get-Date)         Exitting to not screw up something."
                exit 1
            }

        }

    }
    Process
    {
    }
    End
    {
    }
}
