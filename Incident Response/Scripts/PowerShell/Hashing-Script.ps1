# save the old Information preference
$OldInfoPref = $InformationPreference
# enable Information display
$InformationPreference = 'Continue'


$TargetDir = Read-Host 'Please enter the full path to the target Directory '

$FileList = Get-ChildItem -LiteralPath $TargetDir -Recurse -File

$Counter = 0
$Results = foreach ($FL_Item in $FileList)
    {
    $Counter ++
    Write-Information ('Processing file {0} of {1} ...' -f $Counter, $FileList.Count)

    # this will _silently_ skip files that are locked for whatever reason
    $FileHash = Get-FileHash -LiteralPath $FL_Item.FullName -Algorithm MD5 -ErrorAction SilentlyContinue

    # if this is empty, then the "else" block will show "__Error__" in the Hash column
    if ($FileHash)
        {
        [PSCustomObject]@{
            Hash = $FileHash.Hash
            Path = $FileHash.Path
            }
        }
        else
        {
        [PSCustomObject]@{
            Hash = '__Error__'
            Path = $FL_Item.FullName
            }
        } # end >> if ($FileHash)
    } # end >> foreach ($FL_Item in $FileList)

# on screen display
$Results

# send to CSV file    
$Results |
    Export-Csv -LiteralPath "$env:TEMP\FileHashListing.csv" -NoTypeInformation

# restore Information preference
$InformationPreference = $OldInfoPref 
