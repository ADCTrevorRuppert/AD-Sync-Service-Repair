#Path of the files being copied
$sourcePath = "C:\Program Files\Microsoft SQL Server\150\LocalDB\Binn\Templates"
#Resolve any variation of the AD Sync folder to always ensure the right one is selected as the names are random for every install
$destinationRoot = Get-Item "C:\Users\ADSync*`$"
#Full path of the ADSync user profile used to resolve the rest of the path where the files will be copied in order to fix the issue
$destinationPath = "$($destinationRoot.FullName)\AppData\Local\Microsoft\Microsoft SQL Server Local DB\Instances\ADSync2019"
$sourceFiles = @("model.mdf", "modellog.ldf")

$service = Get-Service "ADSync" #Get the AD Sync service and assign it to the variable $service
#If the service is stopped, attempt to start it and wait 60 seconds to ensure the start timeout is reached in order to continue without error
#After sleeping for 60 additional seconds after attempting to start the service we check again to see if the service started or not
if ($service.Status -eq "Stopped")
{
	Start-Service $service | Start-Sleep 60
	#If after attempting to restart the service and waiting 60 seconds the service is still stopped copy the necessary files to the user profile path to resolve the issue and create an event in Application events
	if ((Get-Service "ADSync").Status -eq "Stopped" )
	{
		Write-Host "The service could not be started. Automatic Repair Initiated."
		foreach ($sourceFile in $sourceFiles)
		{
			Copy-Item -Path "$sourcePath\$sourceFile" -Destination $destinationPath -Force -Confirm:$false
			Write-Host "$sourceFile has been copied."
		}
		Start-Service $service
	}
	elseif ((Get-Service "ADSync").Status -eq "StartPending")
	{
		#While the service is still starting we will continue to check it every 2 seconds until it starts or stops
		while ((Get-Service "ADSync").Status -eq "StartPending")
		{
			Start-Sleep 2
		}
	}
}