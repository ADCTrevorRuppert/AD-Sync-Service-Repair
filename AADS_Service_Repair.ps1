<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.196
	 Created on:   	1/7/2022 5:30 PM
	 Created by:   	Trevor Ruppert
	 Organization: 	
	 Filename:     	AADS_Service_Repair.ps1
	===========================================================================
	.DESCRIPTION
		A service to fix the bug in AD Sync version 2.0.25.1 causing the service to not start after a reboot and get stuck "Starting" when manually started.
#>


# Warning: Do not rename Start-MyService, Invoke-MyService and Stop-MyService functions


function Start-MyService
{
	$global:bRunService = $true
	$global:bServiceRunning = $false
	$global:bServicePaused = $false
	#Path of the files being copied
	$global:sourcePath = "C:\Program Files\Microsoft SQL Server\150\LocalDB\Binn\Templates"
	#Resolve any variation of the AD Sync folder to always ensure the right one is selected as the names are random for every install
	$global:destinationRoot = Get-Item "C:\Users\ADSync*`$"
	#Full path of the ADSync user profile used to resolve the rest of the path where the files will be copied in order to fix the issue
	$global:destinationPath = "$($destinationRoot.FullName)\AppData\Local\Microsoft\Microsoft SQL Server Local DB\Instances\ADSync2019"
	$global:sourceFiles = @("model.mdf", "modellog.ldf")
	
}

function Invoke-MyService
{
	$global:bServiceRunning = $true
	while($global:bRunService) {
		try 
		{
			if($global:bServicePaused -eq $false) #Only act if service is not paused
			{
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
				
			}
		}
		catch
		{
			# Log exception in application log
			Write-Host $_.Exception.Message
		}
		# Adjust sleep timing to determine how often your service becomes active
		if($global:bServicePaused -eq $true)
		{
			Start-Sleep -Seconds 20 # if the service is paused we sleep longer between checks
		}
		else
		{
			Start-Sleep –Seconds 10 # a lower number will make your service active more often and use more CPU cycles
		}
	}
	$global:bServiceRunning	= $false
}

function Stop-MyService
{
	$global:bRunService = $false # Signal main loop to exit
	$CountDown = 30 # Maximum wait for loop to exit
	while($global:bServiceRunning -and $Countdown -gt 0)
	{
		Start-Sleep -Seconds 1 # wait for your main loop to exit
		$Countdown = $Countdown - 1
	}
	# Place code to be executed on service stop here
	# Close files and connections, terminate jobs and
	# use remove-module to unload blocking modules
}

function Pause-MyService
{
	# Service is being paused
	# Save state 
	$global:bServicePaused = $true
	# Note that the thread your PowerShell script is running on is not suspended on 'pause'.
	# It is your responsibility in the service loop to pause processing until a 'continue' command is issued.
	# It is recommended to sleep for longer periods between loop iterations when the service is paused.
	# in order to prevent excessive CPU usage by simply waiting and looping.
}

function Continue-MyService
{
	# Service is being continued from a paused state
	# Restore any saved states if needed
	$global:bServicePaused = $false
}

