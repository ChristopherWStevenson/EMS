#	Exports homefolder data for disabled account in specific OU
#	Export contains username, homefolder path (if it exists), and file count/empty
#	Script created by ChristopherWStevenson
#	Requires PS ActiveDirectory module 

#Specify your target OU here
$OU = "OU=DisabledUsers,DC=domain,DC=net"  
#Where to save CSV file
$outputCsv = "c:\temp\DisabledAccountsHomeFolders.csv"

Write-Host "Starting: Disabled accounts homefolder report" -ForegroundColor Cyan

# Import the Active Directory module
Write-Host "Importing ActiveDirectory module..." -ForegroundColor Yellow
Import-Module ActiveDirectory
Write-Host "ActiveDirectory module imported." -ForegroundColor Green

# Get disabled user accounts from the specified OU
Write-Host "Querying disabled users in OU: $OU ..." -ForegroundColor Yellow
$disabledUsers = @(Get-ADUser -Filter {Enabled -eq $false} -SearchBase $OU -Properties HomeDirectory)
$total = $disabledUsers.Count
Write-Host "Found $total disabled user(s)." -ForegroundColor Green

if ($total -eq 0) {
	Write-Host "No disabled users to process. Exiting." -ForegroundColor Magenta
	exit
}

# Initialize an array to hold results
$results = @()
$i = 0

foreach ($user in $disabledUsers) {
	$i++
	$percent = [int](($i / $total) * 100)
	#write progress to screen
	Write-Progress -Activity "Processing disabled users" -Status "Processing $i of ${total}: $($user.SamAccountName)" -PercentComplete $percent

	$homeFolder = $user.HomeDirectory
	$fileCount = ""

	if ([string]::IsNullOrEmpty($homeFolder)) {
		$homeFolder = "Not Assigned"
		$fileCount = ""
	} else {
		# Check if the home folder exists
		if (Test-Path -Path $homeFolder) {
			# Count files and folders in the home folder
			$items = Get-ChildItem -Path $homeFolder -Recurse -ErrorAction SilentlyContinue
			if ($items) {
				$fileCount = $items.Count
			} else {
				$fileCount = "Empty"
			}
		} else {
			$fileCount = "Path Not Found"
		}
	}

	# gather date for each user
	$results += [PSCustomObject]@{
		UserName      = $user.SamAccountName
		HomeFolder    = $homeFolder
		FileCount     = $fileCount
	}
}
Write-Host "Processing complete. Exporting results to CSV: $outputCsv" -ForegroundColor Yellow
# Export results to CSV
$results | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Report generated at $outputCsv" -ForegroundColor Green

