# Server-Scripts

Set of powershell scripts I use to manage Windows servers.

## process-restarter.ps1
Ability to monitor and restart processes based on arguments. Can auto discover processes provided a process name.

Example shortcut

`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -noLogo -ExecutionPolicy unrestricted -command "C:\restarter\process-restarter.ps1 -logfile .\restarter.log -persistent $true"`

Start In: 
`C:\restarter\`
