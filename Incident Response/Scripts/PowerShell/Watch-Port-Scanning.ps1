# This script can be used to monitor for internal port scans on domain and/or private and/or public networks using the firewall logs.
# After the permissions are set correctly on the directory your firewall logs are stored in you may need to restart the device to apply them.
# This can be used to receive an email alert when port scans happen as well as automatically blacklist the ip address performing the port scan
# on the localhost.

    # SET THESE VALUES TO RECEIVE EMAIL ALERTS WHEN DEFINING THE -EmailAlert SWITCH PARMETER
    $To = "alertme@osbornepro.com"
    $From = "do-not-reply@osbornepro.com"
    $SmtpServer = "mail.smtp2go.com"

# This examples test to ensure the current user is a member of the local Administrators group.
    Function Test-Admin {
    [CmdletBinding()]
        param()  # End param

    Write-Verbose "Verifying permissions"
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    If ($IsAdmin)
    {

        Write-Verbose "Permissions verified, continuing execution"

    }  # End If
    Else
    {

        Throw "[x] Insufficient permissions detected. Run this cmdlet in an adminsitrative prompt."

    }  # End Else

}  # End Function Test-Admin

#This cmdlet tests to make sure the files do not already exist before creating them.
#The default value creates the appropriately named firewall log files in C:\Windows\System32\logfiles\Firewall directory.

Function New-FirewallLogFile
{
    [CmdletBinding()]
        param (
            [Parameter(
                Mandatory=$False,
                ValueFromPipeline=$True,
                ValueFromPipelineByPropertyName=$True,
                HelpMessage="[H] Define the directory location to save firewall logs too. `n[E] EXAMPLE: C:\Windows\System32\LogFiles\Firewall"
            )]  # End Parameter
            [String]$Path = "C:\Windows\System32\LogFiles\Firewall"
        )  # End param

BEGIN
{

    Test-Admin

    $FirewallLogFiles = "$Path\domainfw.log","$Path\domainfw.log.old","$Path\privatefw.log","$Path\privatefw.log.old","$Path\publicfw.log","$Path\publicfw.log.old","$Path"

    New-Item -Path $Path -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

}  # End BEGIN
PROCESS
{

  Write-Output "[*] Creating firewall log files in $Path"
  New-Item -Path $FirewallLogFiles -Type File -Force -ErrorAction SilentlyContinue | Out-Null


  Write-Output "[*] Setting permissions on the log files created"
  $Acl = Get-Acl -Path $FirewallLogFiles
  $Acl.SetAccessRuleProtection($True, $False)


  $PermittedUsers = @('NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', 'BUILTIN\Network Configuration Operators', 'NT SERVICE\MpsSvc', 'USAV\sour.pell')
  ForEach ($User in $PermittedUsers)
  {

    $Permission = $User, 'FullControl', 'Allow'

    $AccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $Permission

    $Acl.AddAccessRule($AccessRule)

  }  # End ForEach

}  # End PROCESS
END
{

    $Acl.SetOwner((New-Object -TypeName System.Security.Principal.NTAccount('BUILTIN\Administrators')))
    $Acl | Set-Acl -Path $FirewallLogFiles

}  # End END

}  # End Function New-FirewallLog 
