#Main Menu Function, add options as needed.

function Show-Menu
{
    param (
        [string]$Title = 'Forensic Scripts'
    )
    Clear-Host
    Write-host `n
    Write-Host -f Green "================ $Title ================"
    Write-Host `n
    Write-Host -f DarkCyan "1: Ping Sweep Script."
    Write-Host -f DarkCyan "2: File Search and Hash."
    Write-Host -f DarkCyan "3: Enum Script."
    Write-Host -f DarkCyan "4: Remote Host Processes."
    Write-Host -f DarkCyan "5: Remote Host Connections."
    Write-Host -f DarkCyan "6: Remote Host Local Users/Groups."
    Write-Host -f DarkCyan "7: Remote Host Services."
    Write-Host -f DarkCyan "8: Remote Host Scheduled Tasks."
    Write-Host -f DarkCyan "9: PsSession to remote host."
    Write-Host -f DarkCyan "10: Kill Process on remote host."
    Write-Host -f Red `n "Q: Press 'Q' to quit."
} 

#Functions

Function Ping-Sweep {
        Clear-Host
        Write-Host `n
                $iprange=Read-Host "Please enter IP range to Scan (eg. 10.10.10 or 192.168.0)"
                $ping = new-object System.Net.NetworkInformation.Ping

                $pingselection = Read-Host "Would you like to save Ping Results to a file? (Y or N)"
                    switch ($pingselection)
                {
                    'Y' {
                        'Your file will be saved to Your Desktop as PingResults.txt'
                        'Scan Running, Please wait....'
                        1..254 |%{$ping.send("$iprange.$_",1) |where status -eq Success| 
                         %{ "{0}" -f $_.Address}} | Out-File -Append -FilePath $Env:USERPROFILE\Desktop\PingResults.txt
                     } 'N' {
                        'Your results will be displayed below'
                        1..254 |%{$ping.send("$iprange.$_",1) |where status -eq Success| 
                        %{ "{0}" -f $_.Address}}
                    } 
              }} 

Function SearchAnd-HashFile {
            Clear-Host
            Write-Host `n
                $filecheckselection = Read-Host "Is the file on a remote host? (Y or N)"
                    switch ($filecheckselection)
                     {
                        'Y' {
                         $remotehost = Read-Host "Please enter the remote host IP"
                         $THip = [string]$remotehost
                         Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
                         $filename = Read-Host "Please enter the filename (eg. hack.exe)"
                         $creds = Get-Credential -Message "Please enter valid username and password"
                             'Scan Running, Please wait....'
                         Invoke-Command -ComputerName $remotehost -Credential $creds -ScriptBlock {
                               $f = Get-ChildItem -Path C:\ -Include $using:filename -Force -Recurse -ErrorAction SilentlyContinue
                              Clear-Host
                             Write-Host "FilePath and MD5 Results for [$using:filename]:"
                              Get-FileHash -Path $f -Algorithm MD5 | Select-Object path,hash | fl
                              }

                        } 'N' {
                         $filename = Read-Host "Please enter the filename (eg. hack.exe)"
                            'Scan Running, Please wait....'
                                  $f = Get-ChildItem -Path C:\ -Include $filename -Force -Recurse -ErrorAction SilentlyContinue
                               Clear-Host
                               Write-Host "FilePath and MD5 Results for [$filename]:"
                               Get-FileHash -Path $f -Algorithm MD5 | Select-Object path,hash | fl
            
                       } 
              } }

Function Get-Enum {

    ## Questions for user - INPUT REQUIRED ##
    Clear-Host
#    Set-Variable -Name basicenu -Value $null
    $basicenu = Read-Host 'Do you wish to identify IPCONFIG, NETSTAT, PROCESSES, SERVICES, LOCAL USERS / GROUPS & REGISTRY KEYS? (Y or N)'
#    Set-Variable -Name basicenuAD -Value $null
    $basicenuAD = Read-Host 'Do you wish to identify ADUSERs & key DOMAIN ADMIN GROUPS? (Y or N)'
#    Set-Variable -Name HostIPs -Value $null
    $HostIPs = Read-Host 'List ALL remote IP addresses you wish to run this against? (Eg: 192.168.1.10,192.168.1.20)'
    $THip = [string]$HostIPs
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
    $HostIPs = $HostIPs -replace '[,]',"`n"
#    Set-Variable -Name creds -Value $null
    $creds = Get-Credential
#    Set-Variable -Name date -Value $null
    $date = Get-Date -Format "dd/MM/yyyy-HH:mm:ss"

 

    ## Basic Enumeration Commands ##
    Switch ($basicenu) { 
        ## YES, run the following commands ##
        'Y' {
        $HostIPs | % {
            Invoke-Command -Credential $creds -ComputerName $_ -ScriptBlock {
                Write-Output "-------------------------------------- $using:_ Machine --------------------------------------"
                ## All ipconfig settings ##
                Write-Output "-----IPCONFIG-----"
                ipconfig /all
                ## All TCP & UDP connections
                Write-Output "`n`n-----NETSTAT-----"
                netstat -ano
                ## All local processes ##
                Write-Output "`n`n-----PROCESSES-----"
                Get-Process
                ## All local services and states ##
                Write-Output "`n`n-----SERVICES-----"
                Get-Service | Select-Object Status,Name
                ## All local user accounts & whether or not they are enabled/disabled ##
                Write-Output "`n`n-----LOCAL USERS-----"
                Set-Variable -Name PSversionU -Value $null
                $PSversionU= ((Get-Host).Version).Major
                IF ($PSversionU -gt 2) {
                    Get-LocalUser | Select-Object Name,Enabled
                    }
                ELSE {
                    wmic useraccount list brief
                    }
                ## Who is in the local Administrators Group ##
                Write-Output "`n`n-----LOCAL ADMIN GROUP-----"
                Set-Variable -Name PSversionG -Value $null
                Set-Variable -Name LocalGroup -Value $null
                $PSversionG = ((Get-Host).Version).Major
                IF ($PSversionG -gt 2) {
                     $LocalGroup = (Get-LocalGroup).Name
                    $LocalGroup | % {
                        Get-LocalGroupMember -Group $_
                        }
                    }
                ELSE {
                    wmic path win32_groupuser
                    }
                Write-Output "`n`n-----REGISTRY KEYS-----"
                ## Creates an array containing all possible Run Key locations ##
                Set-Variable -Name RunKeys -Value $null
                $RunKeys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run\",
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce\",
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServices\",
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce\",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce\",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce\Setup\",
                "HKU:\.Default\Software\Microsoft\Windows\CurrentVersion\Run\",
                "HKU:\.Default\Software\Microsoft\Windows\CurrentVersion\RunOnce\",
                "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon",
                "HKLM:\System\CurrentControlSet\Services\",
                "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit",
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\run\",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\run\ "
                ## Disable standard error output = can create problems within your Keys variable (will fill it up with RED SHIT) ##
                $ErrorActionPreference = 'silentlycontinue'
                $RunKeys | ForEach {echo "`n$_" ((Get-Item -Path $_) | Format-Table)}
                } | Out-File -FilePath "$env:USERPROFILE\Desktop\1.txt"
            }
        }
        ## NO, do not run the basic enumeration commands ##
        'N' {
        }
    }
Switch ($basicenuAD) {
        'Y' {
            $HostIPs | % {
                Invoke-Command -Credential $creds -ComputerName $_ -ScriptBlock {
                    ## Who are the Active Directory Users in the system ##
                    ## NOTE: This could be a very large output depending upon the size of the organisation ##
                    Write-Output "`n`n-----AD USERS-----"
                    Get-ADUser -Filter * | Select-Object Name,Enabled
                    ## Who are the Active Directory Administrators group ##
                    Write-Output "`n`n-----AD GRP MBR's ADMINS-----"
                    Get-ADGroupMember -Identity 'Administrators' | Select-Object name,objectClass
                    ## Who are the Active Directory Domain Administrators group ##
                    Write-Output "`n`n-----AD GRP MBR's DOMAIN ADMINS-----"
                    Get-ADGroupMember -Identity 'Domain Admins' | Select-Object name,objectClass
                    ## Who are the Active Directory Schema Administrators group ##
                    Write-Output "`n`n-----AD GRP MBR's SCHEMA ADMINS-----"
                    Get-ADGroupMember -Identity 'Schema Admins' | Select-Object name,objectClass
                    ## Who are the Active Directory Enterprise Administrators group ##
                    Write-Output "`n`n-----AD GRP MBR's ENTERPRISE ADMINS-----"
                    Get-ADGroupMember -Identity 'Enterprise Admins' | Select-Object name,objectClass
                    } | Out-File -Append "$env:USERPROFILE\Desktop\1.txt"
                }
            }
        ## NO, do not run the AD enumeration commands ##
        'N' {
        }
    }
}


Function Kill-RemoteProcess {
        Clear-Host
        Write-Host `n
                $processip=Read-Host "Please enter the host IP address"
                $THip = [string]$processip
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
                $processname = Read-Host "Please enter the name of the process to kill (wildcards accepted)"
                $creds = Get-Credential -Message "Please enter valid username and password"
                $processselection = Read-Host "Ending a critical process can cause the host to crash. Do you want to continue? (Y or N)"
                    switch ($pingselection)
                {
                    'Y' {
                        'Kill Process Running, See below for processes killed....'
                        Invoke-Command -ComputerName $processip -Credential $creds -ScriptBlock {
                           $p = Get-Process | where Name -Like "$using:processname"
                            Stop-Process -InputObject $p
                            Get-Process | Where-Object {$_.HasExited} }
                            

                     } 'N' {
                            
                    } 
              } 
          }




#Main Menu Loop which will only quit when 'q' is entered

do
 {
     Show-Menu
     Write-Host `n
     $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
            Clear-Host
            Ping-Sweep
           
         } '2' {
             Clear-Host
             SearchAnd-HashFile

         } '3' {
             Clear-Host
             Get-Enum
       
         }  '4' {
            Clear-Host
            Write-Host `n
                $hostip=Read-Host "Please enter IP of remote host"
                $THip = [string]$hostip
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
                $creds = Get-Credential -Message "Please enter valid Credentials"
                Invoke-Command -Credential $creds -ComputerName $hostip -ScriptBlock {
                    Get-Process }
           
         } '5' {
             Clear-Host
             Write-Host `n
                $hostip=Read-Host "Please enter IP of remote host"
                $THip = [string]$hostip
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
                $creds = Get-Credential -Message "Please enter valid Credentials"
                Invoke-Command -Credential $creds -ComputerName $hostip -ScriptBlock {
                    Get-NetTCPConnection }

         } '6' {
              Clear-Host
              Write-Host `n
                $hostip=Read-Host "Please enter IP of remote host"
                $THip = [string]$hostip
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
                $creds = Get-Credential -Message "Please enter valid Credentials"
                Invoke-Command -Credential $creds -ComputerName $hostip -ScriptBlock {
                    Get-LocalUser | Select-Object Name,Enabled
                    Get-LocalGroupMember -Group Administrators } 

         } '7' {
              Clear-Host
              Write-Host `n
                $hostip=Read-Host "Please enter IP of remote host"
                $THip = [string]$hostip
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
                $creds = Get-Credential -Message "Please enter valid Credentials"
                Invoke-Command -Credential $creds -ComputerName $hostip -ScriptBlock {
                    Get-Service | Select-Object Status,Name } 

         } '8' {
              Clear-Host
              Write-Host `n
                $hostip=Read-Host "Please enter IP of remote host"
                $THip = [string]$hostip
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
                $creds = Get-Credential -Message "Please enter valid Credentials"
                Invoke-Command -Credential $creds -ComputerName $hostip -ScriptBlock {
                    Get-ScheduledTask } 

          } '9' {
              Clear-Host
              Write-Host `n
                $hostip=Read-Host "Please enter IP of remote host"
                $THip = [string]$hostip
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $THip -Force
                $creds = Get-Credential -Message "Please enter valid Credentials"
                Enter-PSSession -ComputerName $hostip -Credential $creds 

         } '10' {
            Clear-Host
            Kill-RemoteProcess
           
         }


    }

     
     pause
 }
 until ($selection -eq 'q')
