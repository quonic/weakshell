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

Param
(
    # File to import new user from
    [Parameter(Mandatory=$true,
                Position=0)]
    $Folder = "C:\Scripts\NewUsers\"
)

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
        Write-Error "File not found: $Folder"
        Write-Output "Exitting"
        exit
    }
}else{
        Write-Error "File not found: $Folder"
        Write-Output "Exitting"
        exit
    }
if($Folder){
    if( -not (Test-Path -path $Folder\Completed)){
        Write-Error "File not found: $Folder\Completed"
        Write-Output "Exitting"
        exit
    }
}else{
        Write-Error "File not found: $Folder\Completed"
        Write-Output "Exitting"
        exit
    }
#$Users = Import-Csv -Path $File -Delimiter ","

$ErrorList = "Errors: `n"
$ReportList = "Report: `n"
$DoneAnyThing = $false

#Consolidate all csv files into one.
dir $Folder -Filter *.csv | Import-Csv | Export-Csv -Path $Folder\UsersConsolidated.csv -NoTypeInformation

Import-Csv -Path $Folder\UsersConsolidated.csv | ForEach-Object {
    $Name = $_.Firstname + " " + $_.Lastname
    $DisplayName = $_.Firstname + " " + $_.Lastname
    $Alias = $_.Firstname + $_.Lastname.substring(0,1)
    $UserPrincipalName = $_.Firstname + $_.Lastname.substring(0,1) + "@" + $env:USERDNSDOMAIN
    $SamAccountName = $_.Firstname + $_.Lastname.substring(0,1)
    $FirstName = $_.FirstName
    $LastName = $_.LastName
    $Department = $_.Department

    # Check if user exists
    if((Get-Mailbox -Identity $SamAccountName -ErrorAction SilentlyContinue)){
        Write-host "User " + $_.Firstname + $_.Lastname.substring(0,1) + " Exists. Skipping..." -ForegroundColor Yellow
        Write-Error "User " + $_.Firstname + $_.Lastname.substring(0,1) + " Exists. Skipping..."
    }else{
        # Create User in Exchange and AD
        New-Mailbox -Name $Name -DisplayName $DisplayName -Alias $Alias -UserPrincipalName $UserPrincipalName -SamAccountName $SamAccountName -FirstName $FirstName -LastName $LastName -Password (ConvertTo-SecureString $_.Password -AsPlainText -Force) -ResetPasswordOnNextLogon $true
        if( -not (Get-ADUser -Identity $SamAccountName -ErrorAction SilentlyContinue)){
            # Something went wrong, email Admin to investigate
            Write-host "User " + $_.Firstname + $_.Lastname.substring(0,1) + " Not created?" -ForegroundColor Yellow
            $Subject = "MBCRE1: MailBox Creation Report " + $_.Firstname + $_.Lastname.substring(0,1)
            $Body = "Error: Could not create user " + $_.Firstname + $_.Lastname
            send-mailmessage -to $MailTo -from $MailFrom -subject $Subject -Body $Body -Attachments $File -useSSL -SmtpServer "mail.$env:USERDNSDOMAIN"
        }else{
            # Add user to relivant Security Groups

            # Everyone
            Add-ADGroupMember -Identity VPN Access -Member $SamAccountName
            Add-ADGroupMember -Identity CitrixUsers -Member $SamAccountName
            Add-ADGroupMember -Identity TS-Map-Redirect -Member $SamAccountName
            Add-ADGroupMember -Identity Activesync -Member $SamAccountName

            #Departments
            if($Department -match "MIS"){
                Add-ADGroupMember -Identity MIS Department -Member $SamAccountName
                Add-ADGroupMember -Identity MIS -Member $SamAccountName
            }
            if($Department -match "Packaging"){
                Add-ADGroupMember -Identity Packaging Department -Member $SamAccountName
                Add-ADGroupMember -Identity Packaging -Member $SamAccountName
                Add-ADGroupMember -Identity Creative -Member $SamAccountName
                Add-ADGroupMember -Identity showroom -Member $SamAccountName
            }
            if($Department -match "Sales"){
                Add-ADGroupMember -Identity Sales Department -Member $SamAccountName
                Add-ADGroupMember -Identity Sales -Member $SamAccountName
            }
            if(($Department -match "Sampleroom") -or ($Department -match "Operations") -or ($Department -match "Warehouse")){
                Add-ADGroupMember -Identity Operations Department -Member $SamAccountName
                Add-ADGroupMember -Identity Operations -Member $SamAccountName
                Add-ADGroupMember -Identity showroom -Member $SamAccountName
            }
            if($Department -match "Accounting"){
                Add-ADGroupMember -Identity Accounting Department -Member $SamAccountName
                Add-ADGroupMember -Identity Accounting -Member $SamAccountName
                Add-ADGroupMember -Identity Finance -Member $SamAccountName
            }
            if($Department -match "Product Development"){
                Add-ADGroupMember -Identity Product Development -Member $SamAccountName
                Add-ADGroupMember -Identity showroom -Member $SamAccountName
            }
            if(($Department -match "HR") -or ($Department -match "Human Resource") -or ($Department -match "Human Resources")){
                Add-ADGroupMember -Identity HR -Member $SamAccountName
                Add-ADGroupMember -Identity showroom -Member $SamAccountName
            }
        }

        $ReportList = $ReportList + "Created User $SamAccountName `n"
    }
    $DoneAnyThing = $true
}

if($DoneAnyThing){
#Move and rename
Move-Item -Path $Folder\UsersConsolidated.csv -Destination $Folder\Completed\
$Completed = "Users.$((Get-Date).AddDays(-1).ToString('MM-dd-yyyy')).csv"
Rename-Item -Path $Folder\Completed\UsersConsolidated.csv $Completed

send-mailmessage -to $MailTo -from $MailFrom -subject "MBCRC1: MailBox Creation Report" -Body $ReportList -Attachments $Folder\Completed\$Completed -useSSL -SmtpServer "mail.$env:USERDNSDOMAIN" 
}


<#
Example Header and Row for input CSV file

Firstname,Lastname,Password
John,Doe,Welcome1

#>
