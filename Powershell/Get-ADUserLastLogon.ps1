# Inspired by ki01s
#
# Might have some errors
Import-Module ActiveDirectory

<#
.Synopsis
   Get the last time a user(s) last authenticated with AD
.DESCRIPTION
   Get-ADUserLastLogon will return the time that the requested user or users last logged in.
.EXAMPLE
   Get-ADUserLastLogon "UserName"
.EXAMPLE
   $UserList | Get-ADUserLastLogon
#>
function Get-ADUserLastLogon
{
    [CmdletBinding()]
    Param
    (
        # UserName can contain one or more users in a string or an array
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$UserName
    )

    Begin
    {
        $dcs = Get-ADDomainController -Filter {Name -like "*"}
        $Time = 0
        [DateTime]$dt = @()
    }
    Process
    {
        #Get each user and look for their last login time
        $UserName | ForEach
        {
            $user = $_
            #Query each domain controler to find the last date and time user logged in. 
            $dcs | ForEach
            { 

                $hostname = $_.HostName
                $user = Get-ADUser $user | Get-ADObject -Properties lastLogon 

                #compare times from each DC to determine last login time
                if($user.LastLogon -gt $time) 
                {
                    $Time = $User.LastLogon
                }
            }
            #add our user and time to the hash table
            $dt.add($UserName, [DateTime]::FromFileTime($Time))
        }
    }
    End
    {
    #return our user(s) and time(s)
    $dt
    }
}
