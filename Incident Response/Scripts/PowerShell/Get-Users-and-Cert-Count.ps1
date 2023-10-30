########################################################################################
#.Synopsis
#   Outputs paths to users in AD with more than one certificate.
#
#.Description
#   Script outputs the paths to user accounts in Active Directory which have more
#   than one certificate, plus the count of total certificates in AD for each user.
#   This is useful when cleaning up a PKI deployment where duplicate certificates 
#   were not suppressed properly through template options and credentials roaming.
#   Leave $SearchRoot empty to search entire domain, or enter the
#   DN path to an OU, e.g., "LDAP://OU=There,DC=Company,DC=Net".
#   Does not return users with zero certificates because of SizeLimit
#   issues which limit the results returned to 1000 by default:
#   http://msdn.microsoft.com/en-us/library/system.directoryservices.directorysearcher.sizelimit.aspx
#
#.Notes
#  Author: Jason Fossen, Enclave Consulting (http://www.sans.org/windows-security/)  
# Version: 1.1
# Updated: 24.Nov.2012
#   Legal: 0BSD.
########################################################################################


param ($SearchRoot = "")


function DumpUsersAndCertCount ( $SearchRoot = "" )
{
    $DirectoryEntry = new-object System.DirectoryServices.DirectoryEntry -arg $SearchRoot
	$DirectorySearcher = new-object System.DirectoryServices.DirectorySearcher -arg $DirectoryEntry
    $DirectorySearcher.PropertiesToLoad.Add("userCertificate") | out-null
    $DirectorySearcher.Filter = "(&(objectClass=user)(objectCategory=person)(userCertificate=*))"
    $SearchResultCollection = $DirectorySearcher.FindAll()

    $SearchResultCollection | ForEach{$_.Properties} | ForEach {
        $obj = new-Object system.Management.Automation.PSObject
        $path = $_.adspath[0]
        $certs = $_.usercertificate
        $certcount = $certs.count
        add-member -inputobject $obj -membertype NoteProperty -name NumberOfCertificates -value $certcount
        add-member -inputobject $obj -membertype NoteProperty -name UserPath -value $path
        $obj
    } 
    $SearchResultCollection.Dispose()
}


DumpUsersAndCertCount -SearchRoot $SearchRoot 
