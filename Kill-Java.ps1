function Kill-Java
{
    [CmdletBinding()]
    Param
    (
        # Log defaults to "$PSScriptRoot\$env:COMPUTERNAME Java Runtime Removal.log"
        $Log="$PSScriptRoot\$env:COMPUTERNAME Java Runtime Removal.log",

        # Force close Applications running/using java
        [switch]
        $Force,

        # Reinstall Java? Are you crazy?!
        [switch]
        $Reinstall,

        # Java x64 Install file and location
        $Java64Bin="$PSScriptRoot\jre-7u40-windows-x64.exe",

        # Java x86 Install file and location
        $Java86Bin="$PSScriptRoot\jre-7u40-windows-i586.exe",

        # Java Arg, defaults to "/s /v'ADDLOCAL=ALL IEXPLORER=1 MOZILLA=1 JAVAUPDATE=0 REBOOT=suppress' /qn"
        $JavaArgs="/s ADDLOCAL=ALL IEXPLORER=1 MOZILLA=1 JAVAUPDATE=0 REBOOT=suppress /qn",
        
        # Java Args for x64, if this is null JavaArgs will be used.
        $Java64Args,

        # Java Args for x86, if this is null JavaArgs will be used.
        $Java86Args
    )

    Begin
    {
        $Force_exitcode="1618"
        $host.ui.RawUI.WindowTitle="Java Runtime Nuker"
        $arch=$env:PROCESSOR_ARCHITECTURE
        $isXP=$false
        if((Get-WmiObject -class Win32_OperatingSystem).Caption -match "XP"){$isXP=$true}

        # Clear log and create log dir if it's not there
        $mkdirs = $Log.Substring(0,$Log.Length - $Log.split('\')[$Log.split('\').Count - 1].Length)
        New-Item -Path $mkdirs -Type Folder -ErrorAction SilentlyContinue
        Clear-Content $Log -ErrorAction SilentlyContinue
        
        Write-Verbose " JAVA RUNTIME NUKER"
        if($isXP=$true){Write-Verbose ""; Write-Verbose " ! Windows XP detected, using alternate command set to compensate."}
        Write-Verbose ""
        Write-Log "Beginning removal of Java Runtime Environments (series 3-7, x86 and x64) and JavaFX..." -Path $Log

        #Do a quick check to make sure WMI is working
        $wmiproc=Start-Proc "WINMGMT.EXE" "/verifyrepository"
        if($wmiproc.ExitCode -ne 0){
            Write-Log "WMI appears to be working." -Path $Log
        }else{
            Write-Log "WMI appears to be broken. It should still work. Please use WMIDiag.vbs to help diagnose. http://www.microsoft.com/en-us/download/details.aspx?id=7684" -Path $Log
        }

        # I don't think this is needed any more
        # cscript.exe $WMIdiagBin LogFilePath=$env:TEMP
        $killlist="java,javaw,javaws,jqs,jusched,iexplore,iexplorer,firefox,chrome,palemoon".Split(",")
        #########
        #force-CLOSE PROCESSES #-- Do we want to kill Java beForEach-Objecte running? If so, this is where it happens
        #########
        if ($Force) {
	        #Kill all browsers and running Java instances
	        Write-Log "  Looking ForEach-Object and closing all running browsers and Java instances..." -Path $Log

		    $killlist | ForEach-Object {
                # ToDo do some checking id the process is running
			    Write-Output "Searching ForEach-Object $_.exe..."
			    (Get-Process $_).Kill()
		    }
		    Write-Verbose ""
        }else{

        #If we DON'T want to force-close Java, then check ForEach-Object possible running Java processes and abort the script if we find any
        
	        Write-Log "  Variable force_CLOSE_PROCESSES is set to '$Force'. Checking ForEach-Object running processes beForEach-Objecte execution." -Path $Log

	        #Search and report if processes of the list are running and exit if any are running
	        ForEach-Object ($killlist) {
                # ToDo do some checking id the process is running
		        Write-Log "  Searching ForEach $_.exe..."
		        if(Get-Process $_){
				        Write-Log "! ERROR: Process '$_' is currently running, aborting." -Path $Log -Level Error
				        exit $Force_exitcode
			        }
		        }
	        }else{
	        #If we made it this far, we didn't find anything, so we can go ahead
	        Write-Log "  All clear, no running processes found. Going ahead with removal..." -Path $Log
        }


        ########
        #UNINSTALLER SECTION #-- Basically here we just brute-force every "normal" method ForEach
        ########   removing Java, and then resort to more painstaking methods later
        Write-Log "  Targeting individual JRE versions..." -Path $Log
        # ToDo --Remove-- Write-Verbose "$(Get-Date)   This might take a few minutes. Don't close this window."

        #Okay, so all JRE runtimes (series 4-7) use product GUIDs, with certain numbers that increment with each new update (e.g. Update 25)
        #This makes it easy to catch ALL of them through liberal use of WMI wildcards ("_" is single character, "%" is any number of characters)
        #Additionally, JRE 6 introduced 64-bit runtimes, so in addition to the two-digit Update XX revision number, we also check ForEach the architecture 
        #type, which always equals '32' or '64'. The first wildcard is the architecture, the second is the revision/update number.

        #JRE 7
        Write-Log "  JRE 7..." -Path $Log
        (Get-WmiObject win32_product -filter "IdentifyingNumber like '{26A24AE4-039D-4CA4-87B4-2F8__170__FF}'").Uninstall()
        # ToDo Need to do some error checking to eliminate the "InvokeMethodOnNull" error even though it is safe to keep it as is.

        #JRE 6
        Write-Log "  JRE 6..." -Path $Log
        #1st line is For updates 23-xx, after 64-bit runtimes were introduced.
        #2nd line is For updates 1-22, before Oracle released 64-bit JRE 6 runtimes
        (Get-WmiObject win32_product -filter "IdentifyingNumber like '{26A24AE4-039D-4CA4-87B4-2F8__160__FF}'").Uninstall()
        (Get-WmiObject win32_product -filter "IdentifyingNumber like '{3248F0A8-6813-11D6-A77B-00B0D0160__0}'").Uninstall()
        # ToDo Need to do some error checking to eliminate the "InvokeMethodOnNull" error even though it is safe to keep it as is.

        #JRE 5
        Write-Log "  JRE 5..." -Path $Log
        (Get-WmiObject win32_product -filter "IdentifyingNumber like '{3248F0A8-6813-11D6-A77B-00B0D0150__0}'").Uninstall()
        # ToDo Need to do some error checking to eliminate the "InvokeMethodOnNull" error even though it is safe to keep it as is.

        #JRE 4
        Write-Log "  JRE 4..." -Path $Log
        (Get-WmiObject win32_product -filter "IdentifyingNumber like '{7148F0A8-6813-11D6-A77B-00B0D0142__0}'").Uninstall()
        # ToDo Need to do some error checking to eliminate the "InvokeMethodOnNull" error even though it is safe to keep it as is.

        #JRE 3 (AKA "Java 2 Runtime Environment Standard Edition" v1.3.1_00-25)
        Write-Log "  JRE 3 (AKA Java 2 Runtime v1.3.xx)..." -Path $Log
        #This version is so old we have to resort to different methods of removing it
        #Loop through each sub-version
        "01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25".Split(",") | ForEach-Object {
	        Start-Proc "$env:SystemRoot\IsUninst.exe" "-f'$env:ProgramFiles\JavaSoft\JRE\1.3.1_$_\Uninst.isu' -a"
	        Start-Proc "$env:SystemRoot\IsUninst.exe" "-f'${env:ProgramFiles(x86)}\JavaSoft\JRE\1.3.1_$_\Uninst.isu' -a"
        }
        #This one wouldn't fit in the loop above
        Start-Proc "$env:SystemRoot\IsUninst.exe" "-f'$env:ProgramFiles\JavaSoft\JRE\1.3\Uninst.isu' -a"
        Start-Proc "$env:SystemRoot\IsUninst.exe" "-f'${env:ProgramFiles(x86)}\JavaSoft\JRE\1.3\Uninst.isu' -a"

        #Wildcard uninstallers
        Write-Log "  Specific targeting done. Now running WMIC wildcard catchall uninstallation..." -Path $Log
        (Get-WmiObject win32_product -filter "name like '%%J2SE Runtime%%'").Uninstall()
        (Get-WmiObject win32_product -filter "name like 'Java%%Runtime%%'").Uninstall()
        (Get-WmiObject win32_product -filter "name like 'JavaFX%%'").Uninstall()
        # ToDo Need to do some error checking to eliminate the "InvokeMethodOnNull" error even though it is safe to keep it as is.
        Write-Log "  Done." -Path $Log

        #######:
        #REGISTRY CLEANUP #-- This is where it gets hairy. Don't read ahead if you have a weak constitution.
        #######:
        # If not XP then Clean the Registry
        if ($isXP -eq $false) {
            Write-Log "  Commencing registry cleanup..." -Path $Log
            Write-Log "  Searching ForEach-Object residual registry keys..." -Path $Log

            #Search MSIExec installer class hive ForEach-Object keys
            Write-Log "  Looking in HKLM\software\classes\installer\products..." -Path $Log
            reg query HKLM\software\classes\installer\products /f "J2SE Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\software\classes\installer\products /f "Java(TM) 6 Update" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\software\classes\installer\products /f "Java 7" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\software\classes\installer\products /f "Java*Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt

            #Search the Add/Remove programs list (this helps with broken Java installations)
            Write-Log "  Looking in HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall..." -Path $Log
            reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f "J2SE Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f "Java(TM) 6 Update" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f "Java 7" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f "Java*Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt

            #Search the Add/Remove programs list, x86/Wow64 node (this helps with broken Java installations)
            Write-Log "  Looking in HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall..." -Path $Log
            reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f "J2SE Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f "Java(TM) 6 Update" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f "Java 7" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
            reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f "Java*Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt

            #List the leftover registry keys
            Write-Log "  Found these keys..." -Path $Log
            Get-Content "$env:TEMP\java_purge_registry_keys.txt"
            Write-Verbose (Get-Content "$env:TEMP\java_purge_registry_keys.txt").ToString()

            #Backup the various registry keys that will get deleted (if they exist)
            #We do this mainly because we're using wildcards, so we want a method to roll back if we accidentally nuke the wrong thing
            Write-Log "  Backing up keys..." -Path $Log
            if("$env:TEMP\java_purge_registry_backup"){ Remove-Item -force "$env:TEMP\java_purge_registry_backup"}
            New-Item -Path  "$env:TEMP\java_purge_registry_backup"
            #This line walks through the file we generated and dumps each key to a file
            ForEach-Object("$env:TEMP\java_purge_registry_keys.txt".Split('["\n\r"|"\r\n"|\n|\r]')) {(reg query $_) >> $env:TEMP\java_purge_registry_backup\java_reg_keys_1.bak}

            Write-Log "  Keys backed up to $env:TEMP\java_purge_registry_backup\ " -Path $Log
            Write-Log "  This directory will be deleted at next reboot, so get it now if you need it! " -Path $Log

            #Purge the keys
            Write-Log "  Purging keys..." -Path $Log

            #This line walks through the file we generated and deletes each key listed
            #ToDo
            ForEach-Object("$env:TEMP\java_purge_registry_keys.txt".Split('["\n\r"|"\r\n"|\n|\r]')){reg delete $_ /va /f}

            #These lines delete some specific Java locations
            #These keys AREN'T backed up because these are specific, known Java keys, whereas above we were nuking
            #keys based on wildcards, so those need backups in case we nuke something we didn't want to.

            #Delete keys ForEach-Object 32-bit Java installations on a 64-bit copy of Windows
            reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Auto Update" /va /f
            reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Plug-in" /va /f
            reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment" /va /f
            reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Update" /va /f
            reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Web Start" /va /f
            reg delete "HKLM\SOFTWARE\Wow6432Node\JreMetrics" /va /f

            #Delete keys ForEach-Object ForEach-Object 32-bit and 64-bit Java installations on matching Windows architecture
            reg delete "HKLM\SOFTWARE\JavaSoft\Auto Update" /va /f
            reg delete "HKLM\SOFTWARE\JavaSoft\Java Plug-in" /va /f
            reg delete "HKLM\SOFTWARE\JavaSoft\Java Runtime Environment" /va /f
            reg delete "HKLM\SOFTWARE\JavaSoft\Java Update" /va /f
            reg delete "HKLM\SOFTWARE\JavaSoft\Java Web Start" /va /f
            reg delete "HKLM\SOFTWARE\JreMetrics" /va /f

            Write-Log "  Keys purged." -Path $Log
            Write-Log "  Registry cleanup done." -Path $Log

        }else{
            # We are XP so te above was skipped
            Write-Log "! Registry cleanup doesn't work on Windows XP. Skipping..." -Path $Log
        }
        ##########::
        #FILE AND DIRECTORY CLEANUP ::
        ##########::
        #:file_cleanup ---------------------------------
        Write-Log "  Commencing file and directory cleanup..." -Path $Log

        #Kill accursed Java tasks in Task Scheduler
        Write-Log "  Removing Java tasks from the Windows Task Scheduler..." -Path $Log
        if("$env:windir\tasks\Java*.job"){ Remove-Item -Force $env:windir\tasks\Java*.job}
        if("$env:windir\System32\tasks\Java*.job"){Remove-Item -Force $env:windir\System32\tasks\Java*.job}
        if("$env:windir\SysWOW64\tasks\Java*.job"){Remove-Item -Force $env:windir\SysWOW64\tasks\Java*.job}

        #Kill the accursed Java Quickstarter service
        sc query JavaQuickStarterService >NUL
        if( -not ($? -eq 1060)){
	        Write-Log "  De-registering and removing Java Quickstarter service..." -Path $Log
	        net stop JavaQuickStarterService
	        sc delete JavaQuickStarterService
        }

        #Kill the accursed Java Update Scheduler service
        sc query jusched >NUL
        if( -not ($? -eq 1060)) {
	        Write-Log "  De-registering and removing Java Update Scheduler service..." -Path $Log
	        net stop jusched
	        sc delete jusched
        }

        #This is the Oracle method of disabling the Java services. 99% of the time these commands aren't required. 
        if("${env:ProgramFiles(x86)}\Java\jre6\bin\jqs.exe"){ Start-Proc "${env:ProgramFiles(x86)}\Java\jre6\bin\jqs.exe" "-disable"}
        if("${env:ProgramFiles(x86)}\Java\jre7\bin\jqs.exe"){ Start-Proc "${env:ProgramFiles(x86)}\Java\jre7\bin\jqs.exe" "-disable"}
        if("$env:ProgramFiles\Java\jre6\bin\jqs.exe"){ Start-Proc "$env:ProgramFiles\Java\jre6\bin\jqs.exe" "-disable"}
        if("$env:ProgramFiles\Java\jre7\bin\jqs.exe"){ Start-Proc "$env:ProgramFiles\Java\jre7\bin\jqs.exe" "-disable"}
        if("${env:ProgramFiles(x86)}\Java\jre6\bin\jqs.exe"){ Start-Proc "${env:ProgramFiles(x86)}\Java\jre6\bin\jqs.exe" "-unregister"}
        if("${env:ProgramFiles(x86)}\Java\jre7\bin\jqs.exe"){ Start-Proc "${env:ProgramFiles(x86)}\Java\jre7\bin\jqs.exe" "-unregister"}
        if("$env:ProgramFiles\Java\jre6\bin\jqs.exe"){ Start-Proc "$env:ProgramFiles\Java\jre6\bin\jqs.exe" "-unregister"}
        if("$env:ProgramFiles\Java\jre7\bin\jqs.exe"){ Start-Proc "$env:ProgramFiles\Java\jre7\bin\jqs.exe" "-unregister"}
        Start-Proc "msiexec.exe" "/x {4A03706F-666A-4037-7777-5F2748764D10} /qn /norestart"

        #Nuke 32-bit Java installation directories
        Write-Log "  Removing "${env:ProgramFiles(x86)}\Java\jre*" directories..." -Path $Log
	    ForEach-Object(Get-ChildItem -Filter { -like "j2re" -or -like "jre" } "${env:ProgramFiles(x86)}\Java\"){if($_){Remove-Item -Force "$_"}}
	    if("${env:ProgramFiles(x86)}\JavaSoft\JRE"){ Remove-Item -force "${env:ProgramFiles(x86)}\JavaSoft\JRE"}

        #Nuke 64-bit Java installation directories
        Write-Log "  Removing "$env:ProgramFiles\Java\jre*" directories..." -Path $Log
        ForEach-Object(Get-ChildItem -Filter { -like "j2re" -or -like "jre" } "$env:ProgramFiles\Java\"){if($_){Remove-Item -Force "$_"}}
        if("$env:ProgramFiles\JavaSoft\JRE"){ Remove-Item -force "$env:ProgramFiles\JavaSoft\JRE"}

        #Nuke Java installer cache ( thanks to cannibalkitteh )
        Write-Log "  Purging Java installer cache..." -Path $Log
        #XP VERSION
        if ($isXP=$true) {
            #Get list of users, put it in a file, then use it to iterate through each users profile, deleting the AU folder
            $userlist = (Get-Item "$env:SystemDrive\Documents and Settings\*" | Select-Object Name)
            ForEach-Object($userlist){
		        if("$env:SystemDrive\Documents and Settings\$_\AppData\LocalLow\Sun\Java\AU"){Remove-Item -force "$env:SystemDrive\Documents and Settings\$_\AppData\LocalLow\Sun\Java\AU"}
	        }
            ForEach-Object(Get-ChildItem -Filter { -like "j2re" -or -like "jre" } "${env:ProgramFiles(x86)}\Java\"){if($_){Remove-Item -Force "$_"}}
            Get-ChildItem "$env:SystemDrive\Documents and Settings\" | ForEach-Object {
                if(Get-ChildItem "$_\*jre*"){
                    Remove-Item -force "$_"
                }
            }
        } else {
	        #ALL OTHER VERSIONS OF WINDOWS
            #Get list of users, put it in a file, then use it to iterate through each users profile, deleting the AU folder
            $userlist = (Get-Item "$env:SystemDrive\USers\*" | Select-Object Name)
            ForEach-Object($userlist){ Remove-Item -force "$env:SystemDrive\Users\$_\AppData\LocalLow\Sun\Java\AU"}
            #Get the other JRE directories
            Get-ChildItem "$env:SystemDrive\Users\" | ForEach-Object {
                if(Get-ChildItem "$_\*jre*"){
                    Remove-Item -force "$_"
                }
            }
        }

        #Miscellaneous stuff, sometimes left over by the installers
        Write-Log "  Searching for and purging other Java Runtime-related directories..." -Path $Log
        Remove-Item -Force "$env:SystemDrive\1033.mst "
        Remove-Item -Force -Recurse "$env:SystemDrive\J2SE Runtime Environment*"

        Write-Log "  File and directory cleanup done." -Path $Log

        ########:
        #JAVA REINSTALLATION #-- If we wanted to reinstall the JRE after cleanup, this is where it happens
        ########:
    #ToDo: rewite this to download if an URL or copy to local if a Share
        if($Reinstall -eq $true) {
            if ([System.IntPtr]::Size -eq 4) {
                "32-bit"
                Write-Log "! Now installing $Java86bin" -Path $Log
                if($Java32Args -eq $null){
                    "Null"
                    Start-Proc $Java86Bin $JavaArgs
                }else{
                    Start-Proc $Java86Bin $Java86Args
                }
                java -version
                Write-Output "Done." -Path $Log
            } else {
                "64-bit"
                Write-Log "! Now installing $Java64bin" -Path $Log
                if($Java64Args -eq $null){
                    "Null"
                    Start-Proc $Java64Bin $JavaArgs
                }else{
                    Start-Proc $Java64Bin $Java64Args
                }
                java -version
                Write-Output "Done." -Path $Log
            }
        }

        #Done.
        Write-Log "  Registry hive backups: $env:TEMP\java_purge_registry_backup\" -Path $Log
        Write-Log "  Log file: $Log" -Path $Log
        Write-Log "  JAVA NUKER COMPLETE. Recommend rebooting and washing your hands." -Path $Log

        #Return exit code to SCCM/PDQ Deploy/PSexec/etc
        if($Host.Name -eq "Windows PowerShell ISE Host")
        {
            #In ISE
            # Do nothing
        }else
        {
            exit $Force_exitcode
        }

        
    }
    Process
    {
    }
    End
    {
    }

<#
.Synopsis
   Uninstall all versions of Java and remove nearly any trace that it was installed, for a clean install or just removal.
.DESCRIPTION
   This will remove all versions of Java and can also install you intended version of Java.
.EXAMPLE
   Kill-Java
.EXAMPLE
   Kill-Java -Log "c:\Logs\Kill-Java.log"
.EXAMPLE
   Kill-Java -Log "c:\Logs\Kill-Java.log" -Force
.EXAMPLE
   Kill-Java -Log "c:\Logs\Kill-Java.log" -Force -Reinstall
.EXAMPLE
   Kill-Java -Force -Reinstall -JavaBin ".\Java-x64.exe"
.EXAMPLE
   Kill-Java -Force -Reinstall -JavaBin ".\Java-x64.exe" -JavaArgs "/s /v'ADDLOCAL=ALL IEXPLORER=1 MOZILLA=1 JAVAUPDATE=0 REBOOT=suppress' /qn"
#>

}

function Start-Proc{
Param
    (
        # Program
        [Parameter(Mandatory=$true)]
        [string]$program,
        # Args
        [Parameter(Mandatory=$true)]
        [string]$args
    )
    $proc = [System.Diagnostics.Process]::Start($program,$args).WaitForExit()
    return $proc
}

#Stolen from http://poshcode.org/2566
function Write-Log {

	#region Parameters
	
		[cmdletbinding()]
		Param(
			[Parameter(ValueFromPipeline=$true,Mandatory=$true)] [ValidateNotNullOrEmpty()]
			[string] $Message,

			[Parameter()] [ValidateSet(“Error”, “Warn”, “Info”)]
			[string] $Level = “Info”,
			
			[Parameter()] [ValidateRange(1,30)]
			[Int16] $Indent = 0,

			[Parameter()]
			[IO.FileInfo] $Path = ”$env:temp\PowerShellLog.txt”,
			
			[Parameter()]
			[Switch] $Clobber,
			
			[Parameter()]
			[String] $EventLogName,
			
			[Parameter()]
			[String] $EventSource = ([IO.FileInfo] $MyInvocation.ScriptName).Name,
			
			[Parameter()]
			[Int32] $EventID = 1
			
		)
		
	#endregion

	Begin {}

	Process {
		try {			
			$msg = '{0}{1} : {2} : {3}' -f (" " * $Indent), (Get-Date -Format “yyyy-MM-dd HH:mm:ss”), $Level.ToUpper(), $Message
			
			switch ($Level) {
				'Error' { Write-Error $Message }
				'Warn' { Write-Warning $Message }
				'Info' { Write-Host ('{0}{1}' -f (" " * $Indent), $Message) -ForegroundColor White}
			}

			if ($Clobber) {
				$msg | Out-File -FilePath $Path
			} else {
				$msg | Out-File -FilePath $Path -Append
			}
            # My addition
			Write-Verbose -Message $msg

			if ($EventLogName) {
			
				if(-not [Diagnostics.EventLog]::SourceExists($EventSource)) { 
					[Diagnostics.EventLog]::CreateEventSource($EventSource, $EventLogName) 
		        } 

				$log = New-Object System.Diagnostics.EventLog  
			    $log.set_log($EventLogName)  
			    $log.set_source($EventSource) 
				
				switch ($Level) {
					“Error” { $log.WriteEntry($Message, 'Error', $EventID) }
					“Warn”  { $log.WriteEntry($Message, 'Warning', $EventID) }
					“Info”  { $log.WriteEntry($Message, 'Information', $EventID) }
				}
			}

		} catch {
			throw “Failed to create log entry in: ‘$Path’. The error was: ‘$_’.”
		}
	}

	End {}

	<#
		.SYNOPSIS
			Writes logging information to screen and log file simultaneously.

		.DESCRIPTION
			Writes logging information to screen and log file simultaneously. Supports multiple log levels.

		.PARAMETER Message
			The message to be logged.

		.PARAMETER Level
			The type of message to be logged.
		
		.PARAMETER Indent
			The number of spaces to indent the line in the log file.

		.PARAMETER Path
			The log file path.
		
		.PARAMETER Clobber
			Existing log file is deleted when this is specified.
		
		.PARAMETER EventLogName
			The name of the system event log, e.g. 'Application'.
		
		.PARAMETER EventSource
			The name to appear as the source attribute for the system event log entry. This is ignored unless 'EventLogName' is specified.
		
		.PARAMETER EventID
			The ID to appear as the event ID attribute for the system event log entry. This is ignored unless 'EventLogName' is specified.

		.EXAMPLE
			PS C:\> Write-Log -Message "It's all good!" -Path C:\MyLog.log -Clobber -EventLogName 'Application'

		.EXAMPLE
			PS C:\> Write-Log -Message "Oops, not so good!" -Level Error -EventID 3 -Indent 2 -EventLogName 'Application' -EventSource "My Script"

		.INPUTS
			System.String

		.OUTPUTS
			No output.
	#>
}
