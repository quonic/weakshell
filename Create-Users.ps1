Import-Module ActiveDirectory

<#
.SYNOPSIS
   New-User
.DESCRIPTION
   Creates Exhcange MailBox and AD account
.EXAMPLE
   New-User.ps1 "C:\NewUsers\"
   New-User.ps1 -Folder "C:\NewUsers\"
#>
# File to import new user from
[Parameter(Mandatory=$true,
            Position=0)]
$Folder = "C:\Scripts\NewUsers\"


$MailTo = "John Doe <johnd@$env:USERDNSDOMAIN>"
$MailFrom = "MailBoxCreation <mis-noreply@$env:USERDNSDOMAIN>"

# Setup Exchange Connection
$version = (Get-ADObject $("CN=ms-Exch-Schema-Version-Pt,"+$((Get-ADRootDSE).NamingContexts | Where-Object {$_ -like "*Schema*"})) -Property rangeUpper).rangeUpper
if(($version -eq 14726) -or ($version -le 14622) -or ($version -eq 15137)){
    # Upgrade to latest Service Pack for your Exchange verison, does not support Exchange 2003 or below.
    Write-Error "Incorrect Exchange Version: $version"
    Write-Output "Exitting"
}
elseif($version -eq 14625){
    # Running Exchange 2007
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
    cd "c:\program files\microsoft\exchange server\bin"
    . ".\Exchange.ps1"
}
elseif($version -eq 14732){
    # Running Exchange 2010
    . 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1'
    Connect-ExchangeServer -auto
}
elseif($version -eq 15254){
    # Running Exchange 2013
    . 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'
    Connect-ExchangeServer -auto
}
    
# Check if the input file exists, if not exit
if($Folder){
    if( -not (Test-Path -path $Folder)){
        Write-Error "Folder not found: $Folder"
        Write-Output "Exitting"
        exit
    }
}else{
        Write-Error "Folder not found: $Folder"
        Write-Output "Exitting"
        exit
    }
if($Folder){
    if( -not (Test-Path -path $Folder\Completed)){
        Write-Error "Folder not found: $Folder\Completed"
        Write-Output "Exitting"
        exit
    }
}else{
        Write-Error "Folder not found: $Folder\Completed"
        Write-Output "Exitting"
        exit
    }

$ErrorList = "Errors: `n"
$ReportList = "Report: `n"

#Consolidate all csv files into one.
$directoryInfo = Get-ChildItem $Folder -Filter *.csv | Measure-Object
if($directoryInfo.count -eq 0){
    Write-Host "Nothing to do, Exiting..."
    Write-Error "Nothing to do, Exiting..."
    exit
}
Get-ChildItem $Folder -Filter *.csv | Import-Csv | Export-Csv -Path $Folder\UsersConsolidated.csv -NoTypeInformation

#Create Users
Import-Csv -Path $Folder\UsersConsolidated.csv | ForEach-Object {
    $Name = $_.Firstname + " " + $_.Lastname
    $DisplayName = $_.Firstname + " " + $_.Lastname
    $Alias = $_.Firstname + $_.Lastname.substring(0,1)
    $UserPrincipalName = $_.Firstname + $_.Lastname.substring(0,1) + "@" + $env:USERDNSDOMAIN
    $SamAccountName = $_.Firstname + $_.Lastname.substring(0,1)
    $FirstName = $_.FirstName
    $LastName = $_.LastName
    if((Get-Mailbox -Identity $SamAccountName -ErrorAction SilentlyContinue)){
        Write-Host "User " + $_.Firstname + $_.Lastname.substring(0,1) + " Exists. Skipping..." -ForegroundColor Yellow
        Write-Error "User " + $_.Firstname + $_.Lastname.substring(0,1) + " Exists. Skipping..."
    }else{
        New-Mailbox -Name $Name -DisplayName $DisplayName -Alias $Alias -UserPrincipalName $UserPrincipalName -SamAccountName $SamAccountName -FirstName $FirstName -LastName $LastName -Password (ConvertTo-SecureString $_.Password -AsPlainText -Force) -ResetPasswordOnNextLogon $true
        if( -not (Get-ADUser -Identity $SamAccountName -ErrorAction SilentlyContinue)){
            Write-host "User " + $_.Firstname + $_.Lastname.substring(0,1) + " Not created?" -ForegroundColor Yellow
            $Subject = "MBCRE1: MailBox Creation Report " + $_.Firstname + $_.Lastname.substring(0,1)
            $Body = "Error: Could not create user " + $_.Firstname + $_.Lastname
            send-mailmessage -to $MailTo -from $MailFrom -subject $Subject -Body $Body -Attachments $File -useSSL -SmtpServer "mail.$env:USERDNSDOMAIN"
        }
        $ReportList = $ReportList + "Created User $SamAccountName `n"
    }
}

#Move and rename
$Completed = "Users.$((Get-Date).AddDays(-1).ToString('MM-dd-yyyy')).csv"
Move-Item -Path $Folder\UsersConsolidated.csv -Destination $Folder\Completed\
Rename-Item -Path $Folder\Completed\UsersConsolidated.csv $Completed

#Send mail to $MailTo to notify that script completed with the list of users that it created.
Send-MailMessage -to $MailTo -from $MailFrom -subject "MBCRC1: MailBox Creation Report" -Body $ReportList -Attachments $Folder\Completed\$Completed -useSSL -SmtpServer "mail.$env:USERDNSDOMAIN" 



<#
Example Header and Row for input CSV file

Firstname,Lastname,Password
John,Doe,Welcome1

#>
