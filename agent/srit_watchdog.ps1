# srit_watchdog.ps1
# Self-healing mechanism. Checks if Agent is running.

$ErrorActionPreference = "SilentlyContinue"
$root = "C:\ProgramData\SRIT"
$runner = Join-Path $root "srit_runner.ps1"
$logFile = Join-Path $root "logs\srit_watchdog.log"

function Log($msg) {
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [WATCHDOG] $msg"
    $entry | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# Check for running detector processes
$running = Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*srit_detector_*" }

if (-not $running) {
    Log "ALERT: No active detectors found! Attempting restart..."
    
    if (Test-Path $runner) {
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$runner`"" -WindowStyle Hidden
        Log "SUCCESS: Restarted srit_runner.ps1"
    } else {
        Log "CRITICAL: srit_runner.ps1 missing!"
    }
}
