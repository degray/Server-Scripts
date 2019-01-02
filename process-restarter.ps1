####
# (c) 2018 Dave Gray
# Author: Dave "Sinestus" Gray
# This code is licensed under MIT license (https://opensource.org/licenses/MIT)
# Feel free to use and modify as you wish but please don't claim as your own
# 
# Example Usage 
# Discovering processes to watch: .\process-restarter.ps1 -inspectProcess ShooterGameServer.exe
# Running continuously: .\process-restarter.ps1 -logfile .\restarter.log -persistent $true
# Running once: .\process-restarter.ps1 -logfile .\restarter.log
# Enabling Debug Messages: .\process-restarter.ps1 -logfile .\restarter.log -enableDebug $true
####
param(
    #What process name to inspect to seed the process file
    [Parameter(Mandatory=$false)][string]$inspectProcess,
    #Whether or not the script should run persistently
    [Parameter(Mandatory=$false)][bool]$persistent,
    #Location of the log file
    [Parameter(Mandatory=$false)][string]$logfile,
    #Enable debug messaging or not
    [Parameter(Mandatory=$false)][bool]$enableDebug
)


#PARAMETERS - CHANGE AS NEEDED

#How long between interations
$sleepSeconds = 10
#File to hold the process names and arguments to search for
$processFile = ".\processes_list.txt"
#Seperator for process file. If your command arguments use a pipe "|" symbol change this
$seperator = "|"
#How many interations until the process is restarted for unresponsiveness
$interationsForUnresponsiveRestart = 2
#Whether or not you want the script to do an unresponsive check
$doResponsiveCheck = $true


############
#DO NOT CHANGE ANYTHING BELOW THIS LINE
############

#elevation check
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
 {    
  Write-Host "This script needs to be run As Admin as it has to iterate over processes run by other users"
  exit
 }
 
#global variables
$unresponsiveDict = @{}
if (![String]::IsNullOrWhiteSpace($logfile)) {
    if (![System.IO.Path]::IsPathRooted($logfile)) {
        $logfile = [System.IO.Path]::Combine($PSScriptRoot, $logfile)
    }
}

if (![String]::IsNullOrWhiteSpace($processFile)) {
    if (![System.IO.Path]::IsPathRooted($processFile)) {
        $processFile = [System.IO.Path]::Combine($PSScriptRoot, $processFile)
    }
}

function log_file($message) {
    if (![String]::IsNullOrWhiteSpace($logfile)) {
        Out-File -FilePath $logfile -NoClobber -Append -InputObject $message
    }
}

function log($message) {
    $newMessage = "[$(Get-Date -format 'u')] - $($message)"
    Write-Host "$($newMessage)"
    log_file $newMessage
}

function log_debug($message) {
    $newMessage = "[$(Get-Date -format 'u')] - $($message)"
    Write-Debug "$($newMessage)"
    if ($enableDebug) {
        log_file "[$(Get-Date -format 'u')] - DEBUG: $($message)"
    }
}

function start_process($line) {
    if ($line[0] -eq '"') {
        $firstSpacePosition = $line.IndexOf("`"", 1)
    } else {
        $firstSpacePosition = $line.IndexOf(" ")
    }

    $processName = $line.Split($seperator)[0].Trim()
    $processArgs = $line.Split($seperator)[1].Trim()
    log "Starting Process $($processName) with args $($processArgs)"
    Start-Process $processName $processArgs
    $unresponsiveDict[$line] = 0
    log "Started Process $($processName) successfully"
}

if($PSBoundParameters.ContainsKey("enableDebug")) {
    if ($enableDebug) {
        $DebugPreference = 'Continue'
    } else {
        $DebugPreference = 'SilentlyContinue'
    }
} else {
    $enableDebug = $false
}


if($PSBoundParameters.ContainsKey("inspectProcess")) {
    Out-File $processFile
    #((Get-CimInstance Win32_Process | Where-Object {($_.CommandLine -match $([regex]::escape($inspectProcess)) -and $_.CommandLine -notmatch $([regex]::escape($PSCommandPath)))}) | Select-Object -Property CommandLine | format-list * | Out-Host)
    ((Get-CimInstance Win32_Process | Where-Object {($_.CommandLine -match $([regex]::escape($inspectProcess)) -and $_.CommandLine -notmatch $([regex]::escape($PSCommandPath)))}) | %{Out-File -FilePath $processFile -NoClobber -Append -InputObject $($_.ExecutablePath + $seperator + $_.CommandLine.Replace($_.ExecutablePath, "").Replace("`"`"", "").Trim()); Write-Host "Found $($_.CommandLine)"})
} else {
    log "Starting restarter with the following processes:"
    foreach($line in Get-Content $processFile) {
        log $line
    }

    while($true) {
        log_debug "Starting check"
        foreach($line in Get-Content $processFile) 
        {
            $processName = $line.Split($seperator)[0].Trim()
            $processArgs = $line.Split($seperator)[1].Trim()
            $foundProcesses = Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -match $([regex]::escape($processName)) -and $_.CommandLine -match $([regex]::escape($processArgs))}
            if ($foundProcesses.Count -eq 0)
            {
                log "Process $($line) not found. Restarting."
                start_process($line)
            } else {
                if ($doResponsiveCheck) {
                    log_debug "Checking $($line) for responsiveness"
                    $foundProcesses | %{
                        $unresponsive = (Get-Process -Id $_.ProcessId | Where-Object {$_.Responding -eq $false}).count
                        if ($unresponsive -gt 0) {
                            log_debug "Found $($line) to be unresponsive. Checking iterations";
                            if ($unresponsiveDict.ContainsKey($line)) {
                                $unresponsiveDict[$line]++
                            } else {
                                $unresponsiveDict[$line] = 1
                            }

                            if ($unresponsiveDict[$line] -ge $interationsForUnresponsiveRestart) {
                                #try graceful close first then force
                                Get-Process -Id $_.ProcessId | Foreach-Object { $_.CloseMainWindow() | Out-Null } | stop-process –force
                                #sleep before restart
                                start-sleep 3
                                log "Found process $($line) unresponsive... Restarting it."; 
                                start_process($line);
                                continue;
                            } else {
                                log_debug "Found $($line) to be unresponsive but unresponsive interations is only $($unresponsiveDict[$line]) which is less than $($interationsForUnresponsiveRestart). Will check again on next run.";
                            }
                        } else {
                            $unresponsiveDict[$line] = 0
                        }
                    }
                }
                log_debug "Found $($line). Not restarting."
            }           
        }
        if($PSBoundParameters.ContainsKey("persistent") -and $persistent) {
            start-sleep $sleepSeconds
        } else {
            break
        }
    }
}

