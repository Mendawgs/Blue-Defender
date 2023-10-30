#compare files

$fileA = "C:\Enum\240900Jun2020"
$fileB = "C:\Enum\241600Jun2020"
$fileC = "C:\Enum\231600Jun2020"

if(Compare-Object -ReferenceObject $(Get-Content $fileA) -DifferenceObject $(Get-Content $fileB))

 {"files are different"}

Else {"Files are the same"}

Compare-Object -ReferenceObject $(Get-Content $fileA) -DifferenceObject $(Get-Content $fileC) 
