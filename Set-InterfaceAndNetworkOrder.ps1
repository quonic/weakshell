<#
.SYNOPSIS
   I needed this to get the wired connection to be used before the wireless network
   as some users would connect to the guest wireless and not the company wireless.   
.DESCRIPTION
   This script will move the Network adapter and the Network type(Lanman) to the
   top most of the order list.
   
   Run this with $debug and $dontwrite = 1 first time to see output on what will happen.
.EXAMPLE
   ./Set-InterfaceOrderAndNetowrkOrder.ps1
#>

#TODO: Add the ability to input a list of computers.
#  Right now you can build a list and add it the the variable $computer


$remote = 0
$computer = "localhost"

if($remote -eq 1){
    $cred = Get-Credential #Domain\User
    Enter-PSSession $computer -Credential $cred
}

#Settings
#TODO: add a way to set pInfo to the current domain that the computer is joined to.
$pInfo = "my.domain" # This is the search term
$pCheck = "Domain" # could change this to DefaultGateway or something more unique that your are searching for.

$debug = 1
$dontwrite = 1


Push-Location

#Debug:
if($debug -eq 1){
  Write-Host "Reg Before: " (Get-ItemProperty '.\' -Name ProviderOrder).ProviderOrder
}

# --- Network Order

Set-Location hklm:\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order\

# Variables
$order = (Get-ItemProperty '.\' -Name ProviderOrder).ProviderOrder
$topItem = “LanmanWorkstation”
$strNewProvs = $topItem
$i = 1
$exitloop1 = 0

#Split and check if LanmanWorkstation is at the top
$order.Split(",") | ForEach {
    if($exitloop1 -eq 0){
        #Check if we are at the start
        if($i -eq 1){
            #Check if LanmanWorkstation is first in the list
            if($_ -eq $topItem){
                #Debug:
                if($debug -eq 1){
                  Write-Host "Exiting: $_ is at the top"
                }
                #Exit the script, someone else did our job
                $exitloop1 = 1
            }
        }
        #Skip LanmanWorkstation
        if($_ -ne $topItem){
            $i= $i + 1
            $strNewProvs = $strNewProvs + “,” + $_
            #Debug
            #Write-Host "$_ is a token"
        }
    }
}

Write-Host "Attempting to apply to registry: " $strNewProvs

# Write the new string back to the registry
# Note the user running this script needs the needed access to the registry, ie Administrator
Set-ItemProperty '.\' -Name ProviderOrder -Value $strNewProvs

#Debug:
if($debug -eq 1){
  Write-Host "Reg After: " (Get-ItemProperty '.\' -Name ProviderOrder).ProviderOrder
}



# ---- Interface Order

write-host "Getting hklm:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\$pCheck"
$outer = ""
$gotit = 0
Set-Location hklm:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces
Get-ChildItem '.\' | foreach {
    $inter = $_.Name.Split("\")[-1]
    cd $inter
    $varCheck = (Get-ItemProperty ".\" -Name $pCheck).$pCheck
    cd ..
    if ($varCheck -eq $pInfo) {
        $outer = $inter
        $gotit = 1
    }
}

#Check if we got our interface, if not then we quit.
if ($gotit -eq 0) {
    write-host "Well shit.. We didn't find $pInfo."
    $exitloop1 = 1
}
write-host "Got $pCheck"
#---------result = $outer

write-host "Moving on to hklm:\System\CurrentControlSet\Services\Tcpip\Linkage\."

Set-Location hklm:\System\CurrentControlSet\Services\Tcpip\Linkage\

write-host "Getting Bind."

#----Bind
$curBindOrder = (Get-ItemProperty '.\' -Name Bind).Bind
$order = $curBindOrder
$topItem = “\Device\$outer”
$strNewProvs = $topItem
$i = 1
$exitloop2 = 0

$order -Split([environment]::NewLine) | ForEach {
    if($exitloop2 -eq 0){
        if($i -eq 1){
            if($_ -eq $topItem){
                #Debug:
                if($debug -eq 1){
                  Write-Host "Exiting: $_ is at the top"
                }
                Pop-Location
                $exitloop2 = 1
            }
        }
        if($_ -ne $topItem){
            $i= $i + 1
            $strNewProvs = $strNewProvs + [environment]::NewLine + $_
        }
    }
}
$newBindOrder = $strNewProvs

write-host "Getting Export."

#----Export
$curExportOrder = (Get-ItemProperty '.\' -Name Export).Export
$order = $curExportOrder
$topItem = “\Device\Tcpip_$outer”
$strNewProvs = $topItem
$i = 1
$exitloop3 = 0

$order -Split([environment]::NewLine) | ForEach {
    if($exitloop3 -eq 0){
        if($i -eq 1){
            if($_ -eq $topItem){
                #Debug:
                if($debug -eq 1){
                  Write-Host "Exiting: $_ is at the top"
                }
                Pop-Location
                $exitloop3 = 1
            }
        }
        if($_ -ne $topItem){
            $i= $i + 1
            $strNewProvs = $strNewProvs + [environment]::NewLine + $_}
    }
}
$newExportOrder = $strNewProvs

write-host "Getting Route."

#----Route
$curRouteOrder = (Get-ItemProperty '.\' -Name Route).Route
$order = $curRouteOrder
$topItem = '"' + $outer + '"'
$strNewProvs = $topItem
$i = 1
$exitloop4 = 0


$newline = '"' + [environment]::NewLine + '"'
$order -Split($newline) | ForEach {
    if($exitloop4 -eq 0){
        if($i -eq 1){
            if($_ -eq $topItem){
                #Debug:
                if($debug -eq 1){
                    Write-Host "Exiting: $_ is at the top"
                }
                Pop-Location
                $exitloop4 = 1
            }
        }
        if($_ -ne $topItem){
            #Debug:
            if($debug -eq 1){
                write-host $topItem
            }
            $i= $i + 1
            $strNewProvs = $strNewProvs + [environment]::NewLine + $_
        }
    }
}
$newRouteOrder = $strNewProvs
#Debug:
if($debug -eq 1){
  Write-Host $newBindOrder
  Write-Host $newExportOrder
  Write-Host $newRouteOrder
}
if($dontwrite -eq 0){
   if($exitloop1 -eq 0){
       if($exitloop2 -eq 0){
           if($exitloop3 -eq 0){
               if($exitloop4 -eq 0){
                   write-host "Writing to registry."
   
                   Set-ItemProperty '.\' -Name Bind -Value $newBindOrder
                   Set-ItemProperty '.\' -Name Export -Value $newExportOrder
                   Set-ItemProperty '.\' -Name Route -Value $newRouteOrder
   
               }else{write-host "Someone did our work"}
           }else{write-host "Someone did our work"}
       }else{write-host "Someone did our work"}
   }else{write-host "Someone did our work"}
}else{write-host "Test Run!!! Make sure you go through this script before running in production! "}
write-host "Done."

if($remote -eq 1){
    Exit-PSSession
}
Pop-Location
