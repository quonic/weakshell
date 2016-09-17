<#
.SYNOPSIS
   Install Lync 2010 and one patch
.DESCRIPTION
   Check for 32 or 64 and install Lync
.EXAMPLE
   To be run in a GPO
#>

$temp = "c:\temp\lync\"
$share = "\\Server\share\folder"

#Create directory and clean if it exists
Remove-Item "$temp\*"
New-Item $temp -ItemType directory

Set-Location $temp
Copy-Item "$share\*.exe" $temp
Copy-Item "$share\*.msp" $temp

if($env:Processor_Architecture -eq "x86"){
  Write-Host "We are running on a 32bit CPU"
  Write-Host "Running: $temp\LyncSetupx32.exe /Silent /Install /fulluisuppression"
  
  $temp\LyncSetupx32.exe /Silent /Install /fulluisuppression

  Write-Host "Created $temp\LyncInstalled32.txt"

  New-Item $temp\LyncInstalled32.txt -ItemType file
}
else{
  Write-Host "We are running on a 64bit CPU"
  Write-Host "Running: $temp\LyncSetupx64.exe /Silent /Install /fulluisuppression"

  $temp\LyncSetupx64.exe /Silent /Install /fulluisuppression
  
  Write-Host "Created $temp\LyncInstalled64.txt"
  
  New-Item $temp\LyncInstalled64.txt -ItemType file
}
