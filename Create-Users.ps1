Import-Module ActiveDirectory

<#
.Synopsis
   Create users from Excel document in Exchange
.DESCRIPTION
   Create users from the specifed Excel document in the Exchange 2010 Console.
   This assumes that the Exchange 2010 Management Console is installed on the computer running this.
   This also must be ran as administrator and under the 64bit powershell.
.EXAMPLE
   .\Create-Users.ps1 C:\New-Users\MyListOfNewUSers.xlsx
#>
[CmdletBinding()]
[OutputType([int])]
Param
(
    # File to import new user from
    [Parameter(Mandatory=$true,
                Position=0)]
    $File
)

Begin
{
    # Setup Exchange Connection
    . 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1'
    Connect-ExchangeServer -auto
    
    # Check if the input file exists, if not exit
    if( -not (Test-Path -path $File)){
        Write-Error "File not found: $File"
        Write-Output "Exitting"
        exit
    }

    # Save the excel file as a csv file
    $csvFile = ($env:temp + "\" + ((Get-Item -path $File).name).Replace(((Get-Item -path $File).extension),".csv"))
    
    Remove-Item $csvFile -ErrorAction SilentlyContinue
    
    $excelObject = New-Object -ComObject Excel.Application   
    $excelObject.Visible = $false 
    $workbookObject = $excelObject.Workbooks.Open($excelFile) 
    $workbookObject.SaveAs($csvFile,6) # http://msdn.microsoft.com/en-us/library/bb241279.aspx
    $workbookObject.Saved = $true
    $workbookObject.Close()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbookObject) | Out-Null
    $excelObject.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelObject) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers() 
    
    $UList = Import-Csv -path $csvFile
    
    Remove-Item $csvFile -ErrorAction SilentlyContinue

}
Process
{
    ForEach-Object ($UList){
        if((Get-Mailbox -Identity $_.Alias -ErrorAction SilentlyContinue)){
            Write-host "User " + $_.Alias + " Exists. Skipping..." -ForegroundColor Yellow
            Write-Error "User " + $_.Alias + " Exists. Skipping..."
        }else{
            # Create our user here
            New-Mailbox -Name $_.Name -Alias $_.Alias -UserPrincipalName $_.Alias + "@" + $env:USERDNSDOMAIN -SamAccountName $_.SamAccountName -FirstName $_.FirstName -Initials $_.Initials -LastName $_.LastName -Password $_.Password -ResetPasswordOnNextLogon $_.ResetPasswordOnNextLogon
            if( -not (Get-ADUser -Identity $_.Alias)){
                Write-host "User " + $_.Alias + " Not created?" -ForegroundColor Yellow
            }
            # Do anything else with the user here.
        }
    }
}
End
{
}

<#
Example Header and Row for input Excel file

Name,Alias,SamAccountName,FirstName,Initials,LastName,Password,ResetPasswordOnNextLogon
First Last,firstl,firstl,First,FL,Last,Password123,TRUE

#>
