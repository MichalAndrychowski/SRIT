# srit_detector_netconn_ports.ps1
# Watch TCP Connections -> Kill Process (C2)

$ErrorActionPreference = "Stop"
$root = "C:\ProgramData\SRIT"
$conf = Join-Path $root "srit.conf"
$bufferD = Join-Path $root "buffer"
$logsD = Join-Path $root "logs"
New-Item -Force -ItemType Directory $bufferD,$logsD | Out-Null

$logfile = Join-Path $logsD "srit_detector_netconn.log"
function Log($m,[string]$l="INFO"){ "$((Get-Date).ToString('o')) [$l] $m" | Out-File -FilePath $logfile -Append -Encoding UTF8 }

$config = ConvertFrom-StringData -StringData (Get-Content -LiteralPath $conf -Raw)
$MispUrl = ($config['MISP.url']).TrimEnd('/')
$ApiKey = $config['MISP.apikey']
$monitorPorts = $config['LOCAL.monitor_ports'] -split ','
$H = @{ Authorization=$ApiKey; Accept='application/json'; 'Content-Type'='application/json' }

# Function Create-And-Publish-Event (Simplified Buffer Logic)
function Create-And-Publish-Event($info,$tags,$attributes){
    $eBody = @{ Event = @{ info=$info; date=(Get-Date -Format 'yyyy-MM-dd'); threat_level_id='2'; analysis='2'; distribution='3'; published=$false; Tag=($tags|ForEach-Object{ @{ name=$_ } }) } }
    if ($attributes) { $eBody.Event['Attribute'] = $attributes }
    try {
        $json = $eBody | ConvertTo-Json -Depth 10
        $resp = Invoke-RestMethod -Uri "$MispUrl/events/add.json" -Method POST -Headers $H -Body $json -TimeoutSec 5
        try { Invoke-RestMethod -Uri "$MispUrl/events/publish/$($resp.Event.id).json" -Method POST -Headers $H -Body "{}" } catch {}
        return $resp.Event.id
    } catch {
        $filename = "offline_net_$(Get-Date -Format 'yyyyMMdd-HHmmss')_$(Get-Random).json"
        $eBody | ConvertTo-Json -Depth 10 | Out-File (Join-Path $bufferD $filename) -Encoding UTF8
        return 999999
    }
}

Log "Network Watcher Started. Ports: $monitorPorts"
while($true){
    $conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
    foreach($c in $conns){
        if($monitorPorts -contains $c.RemotePort){
            $pidNum = $c.OwningProcess
            try { $proc = Get-Process -Id $pidNum -ErrorAction Stop } catch { continue }
            
            $info = "C2 Connection blocked: $($proc.ProcessName) to port $($c.RemotePort)"
            Log $info "WARN"
            
            # Active Response
            Stop-Process -Id $pidNum -Force -ErrorAction SilentlyContinue
            
            # Report
            Create-And-Publish-Event $info @('technique:T1071','scenario:c2-detection') @(
                @{ type='ip-dst'; value=$c.RemoteAddress; to_ids=$true },
                @{ type='port'; value=$c.RemotePort; to_ids=$false }
            ) | Out-Null
        }
    }
    Start-Sleep -Seconds 5
}
