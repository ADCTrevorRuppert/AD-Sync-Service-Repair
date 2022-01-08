<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.196
	 Created on:   	1/7/2022 5:30 PM
	 Created by:   	denis.zhirovetskiy
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Description of the PowerShell service.
#>


# Warning: Do not rename Start-MyService, Invoke-MyService and Stop-MyService functions


function Start-MyService
{
	# Place one time startup code here.
	# Initialize global variables and open connections if needed
	$global:bRunService = $true
	$global:bServiceRunning = $false
	$global:bServicePaused = $false
}

function Invoke-MyService
{
	$global:bServiceRunning = $true
	while($global:bRunService) {
		try 
		{
			if($global:bServicePaused -eq $false) #Only act if service is not paused
			{
				#Place code for your service here
				#e.g. $ProcessList = Get-Process solitaire -ErrorAction SilentlyContinue
				
				# Use Write-Host or any other PowerShell output function to write to the System's application log
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

