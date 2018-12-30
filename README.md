# Server-Scripts

Set of powershell scripts I use to manage Windows servers.

## process-restarter.ps1
Ability to monitor and restart processes based on arguments. Can auto discover processes provided a process name.

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

