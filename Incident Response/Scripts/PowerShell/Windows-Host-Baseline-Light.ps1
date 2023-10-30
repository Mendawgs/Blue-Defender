#script to Windows Host Baseline Light

pingsweep (CSS) 
#The will give us live hosts and we will use this data to remote into the live host for light baselining
$subnet = "192.168.10."
$start = 1
$stop = 255
While ($start -le $stop)
$ip="$subnet$start"
#write-host $ip
$result=test-connection $ip 



remoting
Invoking

#system info

Host Name
OS Name
OS Version
Hotfixs

ipconfig

get local users # this will give us name of the local users, their password expiry date, last logon time, Account Expires, usermay chnage password

netstat -ano / Get-NetTCPConnection

processz

reg run key

schedule tasks
services that start up

hostfile

log entries user creation and prv esc 
