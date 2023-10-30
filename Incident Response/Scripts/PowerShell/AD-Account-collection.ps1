$creds=get-credential

$DCIP = "192.168.200.1"

set-item WSMAN:\localhost\Client\TrustedHosts -Value '*' -Force
enter-pssession -credential Administrator -computername $DCIP


#gather baseline admin list on in AD (ensure import module active directory is available)
import-module activeDirectory
get-adgroupmember "Domain Admins"
get-adgroupmember "Server Admins"
get-adgroupmember "Workstation Admins"
get-adgroupmember "Administrators" -recursive

<## user query-lastlogin time and actual name

net user User082
import-module activeDirectory
get-aduser User082

#GWMI win32_useraccount
#get-localuser | getmember
#get-localuser | select Name,Lastlogon,SID

#> 

exit
clear-item WSMAN:\localhost\Client\TrustedHosts 
