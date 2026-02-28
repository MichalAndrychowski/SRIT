# srit_runner.ps1
# Main Agent Orchestrator

$root = "C:\ProgramData\SRIT"
$logs = Join-Path $root "logs"
Write-Host "--- SRIT SECURITY SUITE ---" -ForegroundColor Cyan

# Kill old instances to prevent duplicates
Write-Host "Stopping previous instances..." -ForegroundColor Yellow
Get-Job | Remove-Job -Force
Get-Process | Where-Object {$_.CommandLine -like "*srit_detector_*"} | Stop-Process -Force -ErrorAction SilentlyContinue

# List of detectors
$detectors = @(
    "srit_detector_downloads.ps1",
    "srit_detector_netconn_ports.ps1",
    "srit_detector_encoded.ps1",
    "srit_detector_eml_extract.ps1",
    "srit_detector_hosts_changes.ps1"
)

Write-Host "Starting detectors..." -ForegroundColor Yellow

foreach ($d in $detectors) {
    $scriptPath = Join-Path $root $d
    if (Test-Path $scriptPath) {
        # Start as background job
        Start-Job -FilePath $scriptPath -Name $d
        Write-Host " [OK] Started: $d" -ForegroundColor Green
    } else {
        Write-Host " [ERR] Missing: $d" -ForegroundColor Red
    }
}

Write-Host "`nAll systems operational."
Write-Host "Logs are located in $logs"
Write-Host "Press Enter to exit (Detectors will keep running in background)..."
Read-Host
