#move to directory of scripts and psexec
cd "\\env-share\IR-Scripts" 

#DC ip address
$IP = Read-host -Prompt 'Input DC ip address' 

#asks for credentials and stores them
$creds = get-credential 

set-item WSMAN:\localhost\Client\TrustedHosts -Value '*' -Force
$script = Read-host -Prompt 'What Script would you like to run? i.e Winenum.ps1'
$s = get-content -raw $script
