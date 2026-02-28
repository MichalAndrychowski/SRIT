# srit_detector_downloads.ps1
# Watch Downloads -> MISP + BUFFER (Offline) + QUARANTINE (Active Response)

$ErrorActionPreference = "Stop"

# Paths
$root   = "C:\ProgramData\SRIT"
$conf   = Join-Path $root "srit.conf"
$logsD  = Join-Path $root "logs"
$stateD = Join-Path $root "state"
$stateF = Join-Path $stateD "downloads_state.json"
$quarantine = Join-Path $root "Quarantine"
$bufferD    = Join-Path $root "buffer"

New-Item -Force -ItemType Directory $logsD,$stateD,$quarantine,$bufferD | Out-Null

# Logging
$logfile = Join-Path $logsD "srit_detector_downloads.log"
function Log($m,[string]$l="INFO"){ 
    $entry = "$((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')) [$l] $m"
    Write-Host $entry -ForegroundColor Green 
    $entry | Out-File -FilePath $logfile -Append -Encoding UTF8 
}

# Config
if (-not (Test-Path $conf)) { Write-Host "CRITICAL: Missing srit.conf"; exit 1 }
$config = ConvertFrom-StringData -StringData (Get-Content -LiteralPath $conf -Raw)
$MispUrl = ($config['MISP.url']).TrimEnd('/')
$ApiKey  = $config['MISP.apikey']
$dedupMin = if ($config['LOCAL.dedup_minutes']) { [int]$config['LOCAL.dedup_minutes'] } else { 30 }

if (-not $ApiKey) { Write-Host "CRITICAL: MISP.apikey missing"; exit 1 }
$H = @{ Authorization=$ApiKey; Accept='application/json'; 'Content-Type'='application/json'; 'User-Agent'='SRIT-Detector/downloads-1.1' }

# State
if (Test-Path $stateF) { 
    try { 
        $jsonObj = Get-Content -LiteralPath $stateF -Raw | ConvertFrom-Json
        $state = @{}
        if ($jsonObj) { $jsonObj.PSObject.Properties | ForEach-Object { $state[$_.Name] = $_.Value } }
    } catch { $state = @{} } 
} else { $state = @{} }

function Save-State(){ ($state|ConvertTo-Json -Depth 5) | Out-File -FilePath $stateF -Encoding UTF8 }

# --- CORE FUNCTION (MISP + BUFFER + PUBLISH) ---
function Create-And-Publish-Event($info,$tags,$attributes){
    $eBody = @{ Event = @{ info=$info; date=(Get-Date -Format 'yyyy-MM-dd'); threat_level_id='3'; analysis='2'; distribution='3'; published=$false; Tag=($tags|ForEach-Object{ @{ name=$_ } }) } }
    if ($attributes) { $eBody.Event['Attribute'] = $attributes }
    
    try {
        # TRY ONLINE SEND
        $jsonPayload = $eBody | ConvertTo-Json -Depth 10
        $resp = Invoke-RestMethod -Uri "$MispUrl/events/add.json" -Method POST -Headers $H -Body $jsonPayload -TimeoutSec 5 -ErrorAction Stop
        
        $id = $resp.Event.id
        Log ">>> ONLINE SUCCESS: Event ID $id" "INFO"
        
        # Publish current
        try { Invoke-RestMethod -Uri "$MispUrl/events/publish/$id.json" -Method POST -Headers $H -Body "{}" -ErrorAction SilentlyContinue } catch {}

        # FLUSH BUFFER
        if (Test-Path "$bufferD\*.json") {
            Get-ChildItem "$bufferD\*.json" | Select-Object -First 3 | ForEach-Object {
                try {
                    # Add
                    $flushResp = Invoke-RestMethod -Uri "$MispUrl/events/add.json" -Method POST -Headers $H -Body (Get-Content $_.FullName -Raw) -TimeoutSec 5 -ErrorAction Stop
                    $flushId = $flushResp.Event.id
                    # Publish
                    Invoke-RestMethod -Uri "$MispUrl/events/publish/$flushId.json" -Method POST -Headers $H -Body "{}" -ErrorAction SilentlyContinue
                    # Delete
                    Remove-Item $_.FullName -Force
                    Log "BUFFER FLUSH: Sent & Published old event $($_.Name)" "INFO"
                } catch {}
            }
        }
        return $id

    } catch {
        # OFFLINE MODE
        Log "!!! NETWORK ERROR. BUFFERING..." "WARN"
        $filename = "offline_$(Get-Date -Format 'yyyyMMdd-HHmmss')_$(Get-Random).json"
        $eBody | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path $bufferD $filename) -Encoding UTF8
        Log "BUFFER: Saved to $filename" "WARN"
        return 999999 # Fake ID to allow Quarantine
    }
}

# --- WATCHER ---
$downloads = "C:\Users\Student\Downloads"
if (-not (Test-Path $downloads)) { Throw "Downloads folder not found: $downloads" }

$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path = $downloads
$fsw.Filter = "*.exe"
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

Log "Active Watcher Started: $downloads" "INFO"

while ($true) {
    try {
        $result = $fsw.WaitForChanged([System.IO.WatcherChangeTypes]::Created, 1000)
        if ($result.TimedOut) { continue }
        $fileName = $result.Name
        $fullPath = Join-Path $downloads $fileName
        Start-Sleep -Seconds 2 
        if (-not (Test-Path $fullPath)) { continue }

        try { $sha = (Get-FileHash -Path $fullPath -Algorithm SHA256 -ErrorAction Stop).Hash } catch { continue }

        if ($state.ContainsKey($sha)) {
            $last = [DateTime]$state[$sha]
            if ((Get-Date) -lt $last.AddMinutes($dedupMin)) { continue }
        }

        $info = "Suspicious download: $fileName on $env:COMPUTERNAME"
        $tags = @('scenario:suspicious-download','technique:T1204','tlp:amber')
        $attrs = @(
            @{ type='sha256'; value=$sha; category='Payload delivery'; to_ids=$true },
            @{ type='filename'; value=$fileName; category='Payload delivery'; to_ids=$false }
        )

        $evId = Create-And-Publish-Event $info $tags $attrs
        
        if ($evId) {
            $state[$sha] = (Get-Date).ToString("o")
            Save-State
            try {
                $dest = Join-Path $quarantine "$fileName.vir"
                Move-Item -Path $fullPath -Destination $dest -Force -ErrorAction Stop
                Log "RESPONSE: Quarantined $fileName" "WARN"
            } catch { Log "Quarantine Failed: $_" "ERROR" }
        }
    } catch { Log "Loop Error: $_" "ERROR" }
}
