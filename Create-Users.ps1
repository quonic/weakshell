Import-Module ActiveDirectory

Function NewUser{
<#
.SYNOPSIS
   NewUser
.DESCRIPTION
   Creates Exhcange MailBox and AD account
.EXAMPLE
   NewUser.ps1 "C:\temp\userlist.csv"
   NewUser.ps1 -File "C:\temp\userlist.csv"
#>

    Param
    (
        # File to import new user from
        [Parameter(Mandatory=$true,
                    Position=0)]
        $File = ".\userlist.csv"
    )

    Begin
    {
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
        if($File){
            if( -not (Test-Path -path $File)){
                Write-Error "File not found: $File"
                Write-Output "Exitting"
                exit
            }
        }else{
                Write-Error "File not found: $File"
                Write-Output "Exitting"
                exit
            }
    }
    Process{
        #$Users = Import-Csv -Path $File -Delimiter ","

        $ErrorList = "Errors: `n"
        $ReportList = "Report: `n"


        Import-Csv -Path $File | ForEach-Object {
            $Name = $_.Firstname + " " + $_.Lastname
            $DisplayName = $_.Firstname + " " + $_.Lastname
            $Alias = $_.Firstname + $_.Lastname.substring(0,1)
            $UserPrincipalName = $_.Firstname + $_.Lastname.substring(0,1) + "@" + $env:USERDNSDOMAIN
            $SamAccountName = $_.Firstname + $_.Lastname.substring(0,1)
            $FirstName = $_.FirstName
            $LastName = $_.LastName
            if((Get-Mailbox -Identity $SamAccountName -ErrorAction SilentlyContinue)){
                Write-host "User " + $_.Firstname + $_.Lastname.substring(0,1) + " Exists. Skipping..." -ForegroundColor Yellow
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
        send-mailmessage -to $MailTo -from $MailFrom -subject "MBCRC1: MailBox Creation Report" -Body $ReportList -Attachments $File -useSSL -SmtpServer "mail.$env:USERDNSDOMAIN"
    }
    End
    {
    }
}
<#
Example Header and Row for input CSV file

Firstname,Lastname,Password
John,Doe,Welcome1

#>
