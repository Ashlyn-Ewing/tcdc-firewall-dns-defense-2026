# TCDC SMC 2026 - read-only rival service inventory
# Scope: exact published host/port pairs for Teams 1, 3, 4, 5, 6 (Team 2 excluded).
# Requires approval, hands-on authorization, and an authorized execution location.
[CmdletBinding()]
param(
  [switch]$Run,
  [switch]$Authorized,
  [ValidateRange(300,10000)][int]$TimeoutMs = 1200,
  [ValidateRange(500,30000)][int]$DelayMs = 1000,
  [string]$ReportDirectory = '.\reports'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$services = @(
  @{Name='opnsense'; Segment=40; Last=1; Port=443; Type='Firewall GUI'},
  @{Name='ns1'; Segment=10; Last=53; Port=53; Type='DNS TCP'},
  @{Name='ftp-archive'; Segment=10; Last=21; Port=21; Type='FTP'},
  @{Name='ssh-workstation'; Segment=10; Last=22; Port=22; Type='SSH'},
  @{Name='artifactorium'; Segment=10; Last=80; Port=80; Type='HTTP'},
  @{Name='ad'; Segment=20; Last=88; Port=389; Type='LDAP'},
  @{Name='mqtt'; Segment=30; Last=49; Port=1883; Type='MQTT'},
  @{Name='ipcam'; Segment=0; Last=0; Port=80; Type='Camera HTTP'}
)
$targets = @(
  foreach ($team in @(1,3,4,5,6)) {
    foreach ($service in $services) {
      $ip = if ($service.Name -eq 'ipcam') { "10.150.0.$team" } else { "10.$(100+$team).$($service.Segment).$($service.Last)" }
      [pscustomobject]@{ Team=$team; Host=$service.Name; IP=$ip; Port=[int]$service.Port; ExpectedService=$service.Type }
    }
  }
)
Write-Host "Derived $($targets.Count) exact address/port combinations for rival Teams 1,3,4,5,6."
$targets | Format-Table Team,Host,IP,Port,ExpectedService -AutoSize
if (-not $Run) { Write-Host 'PREVIEW ONLY: No traffic sent. For approved checks pass -Run -Authorized.'; return }
if (-not $Authorized) { throw 'Requires -Authorized following staff approval and hands-on authorization.' }
Write-Warning 'Run only from a staff-permitted client and keep results inside approved competition storage (R23).'
$confirmation = Read-Host 'Type CHECK to make up to 40 rate-limited TCP connection attempts'
if ($confirmation -cne 'CHECK') { Write-Host 'Cancelled'; return }
New-Item -ItemType Directory -Force -Path $ReportDirectory | Out-Null
$results = New-Object System.Collections.Generic.List[object]
foreach ($target in $targets) {
  $tcp = New-Object System.Net.Sockets.TcpClient
  $connected = $false
  $result = 'Timeout/filtered'
  try {
    $pending = $tcp.ConnectAsync([string]$target.IP,[int]$target.Port)
    if ($pending.Wait($TimeoutMs) -and $tcp.Connected) { $connected = $true; $result = 'TCP connected' }
  } catch { $result = 'Connection failed' } finally { $tcp.Dispose() }
  [void]$results.Add([pscustomobject]@{ CheckedAt=(Get-Date).ToString('o'); Team=$target.Team; Host=$target.Host; IP=$target.IP; Port=$target.Port; ExpectedService=$target.ExpectedService; TCPReachable=$connected; Result=$result })
  Write-Host ("Team {0} {1}:{2}: {3}" -f $target.Team,$target.IP,$target.Port,$result)
  Start-Sleep -Milliseconds $DelayMs
}
$out = Join-Path $ReportDirectory ('tcdc-rival-reachability-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.csv')
$results | Export-Csv -LiteralPath $out -NoTypeInformation -Encoding UTF8
Write-Host "Report: $out"
Write-Warning 'TCP reachability alone does not prove a vulnerability, application health, or exploitability.'
