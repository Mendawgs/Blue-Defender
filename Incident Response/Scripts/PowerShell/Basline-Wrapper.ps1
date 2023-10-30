<# ###########################################################

This is a simple wrapper for Baseline.ps1.  Use this to
delete prior baselines older than 21 days (or whatever
number you choose) and then create a new baseline.
Edit the $SnapshotDir variable to change the path; the
New-Baseline.ps1 script must be in this folder.  Edit the
shared folder path at the bottom, if you want to move the
zip to a centralized locations for all baseline zips.
To keep it simple, this script includes no error handling
or logging, so these should be added in real life.

########################################################### #>

# Local folder where the New-Baseline.ps1 script is placed and
# where the actual baseline data folders will be kept:
$BaselineDir = 'C:\Data\Baselines'


# Make that directory the current:
cd $BaselineDir


# Get a datetime object representing 21 days ago, or
# edit the number to change the number of days:
$DaysAgo = (get-date).AddDays(-21)


# Delete any old zip files:
dir -Path (Join-Path -Path $BaselineDir -ChildPath '*.zip') |
where { $_.LastWriteTime -lt $DaysAgo } |
Where { $_.Name -match '^.+\-20\d\d\-\d+\-\d+\-\d+\-\d+\.zip$' } |
del -force 


# Create a new baseline folder in current dir:
.\New-Baseline.ps1 -Verbose


# Get all baseline folders in current directory:
$baselinefolders = dir -Directory | Where { $_.Name -match '^.+\-20\d\d\-\d+\-\d+\-\d+\-\d+$' }


# Compress each folder into a zip with the same name:
$baselinefolders | foreach { Compress-Archive -Path $_.FullName -DestinationPath $_.Name -CompressionLevel Optimal } 


# Delete any baseline folders:
$baselinefolders | del -Recurse -Force 


# Move all zips into a centralized share:
# dir *.zip | Move-Item -Force -Destination \\server\share 
