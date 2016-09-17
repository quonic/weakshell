<#
.SYNOPSIS
   I needed this to get the wired connection to be used before the wireless network
   as some users would connect to the guest wireless and not the company wireless.
.DESCRIPTION
   This script will move the Network adapter and the Network type(Lanman) to the
   top most of the order list.
   
   -Term "Domain"
        Should be set to "Domain", but could use "DefaultGateway" or something more unique that your are searching for.
   -Search "domain.com"
        Set to what you want to search for.
   -Debug $false
        Will output debug strings.
   -Force $true
        Should be used to actually make changes to the registry.
   
.EXAMPLE
   Set-InterfaceOrderAndNetowrkOrder.ps1 -Search "domain.com" -Term "Domain"
   Set-InterfaceOrderAndNetowrkOrder.ps1 -Search "domain.com" -Term "Domain" -Debug
   Set-InterfaceOrderAndNetowrkOrder.ps1 -Search "domain.com" -Term "Domain" -Debug -Force
#>

param (
    [string]$Search = $(throw "-Search is required. Recommend to set to your domain that is set from you DHCP server."),
    [string]$Term = $(throw '-Term is required. Recommend to set as "Domain" or "DefaultGateway"'),
    [switch]$Debug = $true,
    [switch]$Force = $true
)


    Push-Location
    Set-Location hklm:\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order\
    
    #Debug:
    if($debug -eq $true){
      Write-Host "Reg Before: " (Get-ItemProperty '.\' -Name ProviderOrder).ProviderOrder
    }

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
                    if($debug -eq $true){
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
    if($debug -eq $true){
      Write-Host "Reg After: " (Get-ItemProperty '.\' -Name ProviderOrder).ProviderOrder
    }



    # ---- Interface Order

    write-host "Getting hklm:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\$Term"
    $outer = ""
    $gotit = 0
    
    Get-ChildItem '.\' | foreach {
        $inter = $_.Name.Split("\")[-1]
        cd $inter
        $varCheck = (Get-ItemProperty ".\" -Name $Term).$Term
        cd ..
        if ($varCheck -eq $Search) {
            $outer = $inter
            $gotit = 1
        }
    }

    #Check if we got our interface, if not then we quit.
    if ($gotit -eq 0) {
        write-host "Well shit.. We didn't find $Search."
        $exitloop1 = 1
    }
    write-host "Got $Term"
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
                    if($debug -eq $true){
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
                    if($debug -eq $true){
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
                    if($debug -eq $true){
                        Write-Host "Exiting: $_ is at the top"
                    }
                    Pop-Location
                    $exitloop4 = 1
                }
            }
            if($_ -ne $topItem){
                #Debug:
                if($debug -eq $true){
                    write-host $topItem
                }
                $i= $i + 1
                $strNewProvs = $strNewProvs + [environment]::NewLine + $_
            }
        }
    }
    $newRouteOrder = $strNewProvs
    #Debug:
    if($debug -eq $true){
      Write-Host $newBindOrder
      Write-Host $newExportOrder
      Write-Host $newRouteOrder
    }
    if($Force -eq $true){
       $maths = $exitloop1 + $exitloop2 + $exitloop3 + $exitloop4
       if($maths -eq 0){
          write-host "Writing to registry."
          Set-ItemProperty '.\' -Name Bind -Value $newBindOrder
          Set-ItemProperty '.\' -Name Export -Value $newExportOrder
          Set-ItemProperty '.\' -Name Route -Value $newRouteOrder
       }else{write-host "Someone did our work or something is wrong. Check debug statments."}
    }else{write-host "Test Run!!! Make sure you go through this script before running in production! "}
    write-host "Done."


    Pop-Location
