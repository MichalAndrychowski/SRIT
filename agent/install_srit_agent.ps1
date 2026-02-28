# install_srit_agent.ps1
# SRIT Agent Installer - Universal Version (With Watchdog)
# Run as Administrator

$ErrorActionPreference = "Stop"
Write-Host "--- SRIT AGENT INSTALLER ---" -ForegroundColor Cyan

# 1. Check Admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "ERROR: Run this script as Administrator!"
    exit
}

# 2. Define paths
$installDir = "C:\ProgramData\SRIT"
$sourceDir = $PSScriptRoot 
$dirs = @("logs", "state", "Quarantine", "buffer")

# 3. Create directory structure
Write-Host "[*] Creating folders..." -ForegroundColor Yellow
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
foreach ($d in $dirs) {
    $p = Join-Path $installDir $d
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# 4. Copy scripts
Write-Host "[*] Installing scripts..." -ForegroundColor Yellow
$filesToCopy = @("srit.conf", "srit_runner.ps1", "srit_detector_*.ps1", "srit_watchdog.ps1")
$foundAny = $false

foreach ($pattern in $filesToCopy) {
    $files = Get-ChildItem -Path $sourceDir -Filter $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        Copy-Item -Path $file.FullName -Destination $installDir -Force
        Write-Host "    -> Copied: $($file.Name)" -ForegroundColor Gray
        $foundAny = $true
    }
}

if (-not $foundAny) {
    Write-Warning "WARNING: No scripts found! Are they in the same folder as this installer?"
}

# 5. Set permissions for Student
$studentUser = "Student" 
Write-Host "[*] Setting permissions for user: $studentUser..." -ForegroundColor Yellow
$studentPath = "C:\Users\$studentUser"
if (Test-Path $studentPath) {
    icacls $studentPath /grant "Administrators:(OI)(CI)F" /T | Out-Null
    Write-Host "    -> Permissions granted." -ForegroundColor Green
} else {
    Write-Warning "    -> Folder $studentPath not found."
}

# 6. Enable ScriptBlockLogging
Write-Host "[*] Configuring Registry..." -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "EnableScriptBlockLogging" -Value 1
Write-Host "    -> Registry updated." -ForegroundColor Green

# 7. Auto-Start Task (Boot)
Write-Host "[*] Setting up Auto-Start Task..." -ForegroundColor Yellow
$taskName = "SRIT_Security_Agent_Boot"
$runnerPath = Join-Path $installDir "srit_runner.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$runnerPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup

try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest | Out-Null
    Write-Host "    -> Boot Task registered." -ForegroundColor Green
} catch { Write-Warning "    -> Failed to register Boot Task." }

# 8. Watchdog Task (Repeat every 5 mins)
Write-Host "[*] Setting up Watchdog Task..." -ForegroundColor Yellow
$wdName = "SRIT_Security_Watchdog"
$wdPath = Join-Path $installDir "srit_watchdog.ps1"
$wdAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$wdPath`""
$wdTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)

try {
    Unregister-ScheduledTask -TaskName $wdName -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName $wdName -Action $wdAction -Trigger $wdTrigger -User "SYSTEM" -RunLevel Highest | Out-Null
    Write-Host "    -> Watchdog Task registered (Every 5 mins)." -ForegroundColor Green
} catch { Write-Warning "    -> Failed to register Watchdog." }

Write-Host "`n[SUCCESS] Installation complete." -ForegroundColor Cyan
Start-Sleep -Seconds 3
