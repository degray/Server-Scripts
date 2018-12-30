# Server-Scripts

Set of powershell scripts I use to manage Windows servers.

## process-restarter.ps1
Ability to monitor and restart processes based on arguments. Can auto discover processes provided a process name.

1. Auto discover processes based off of process name
2. Logging supported both normal and verbose (debug)
3. Unresponsive check supported
4. Can be run in persistent mode or one time mode
5. Configurable interval time, unresponsive interations, and responsive check statuses

Example Usage 
```
Discovering processes to watch: .\process-restarter.ps1 -inspectProcess ShooterGameServer.exe
Running continuously: .\process-restarter.ps1 -logfile .\restarter.log -persistent $true
Running once: .\process-restarter.ps1 -logfile .\restarter.log
Enabling Debug Messages: .\process-restarter.ps1 -logfile .\restarter.log -enableDebug $true```


Example shortcut

`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -noLogo -ExecutionPolicy unrestricted -command "C:\restarter\process-restarter.ps1 -logfile .\restarter.log -persistent $true"`

Start In: 
`C:\restarter\`

