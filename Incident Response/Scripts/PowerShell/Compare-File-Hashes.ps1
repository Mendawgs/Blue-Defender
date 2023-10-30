#Get then compare File Hashes

$fileA = "C:\fso\myfile.txt"

$fileB = "C:\fso\CopyOfmyfile.txt"

$fileC = "C:\fso\changedMyFile.txt"

if((Get-FileHash $fileA).hash  -ne (Get-FileHash $fileC).hash)

 {"files are different"}

Else {"Files are the same"} 
