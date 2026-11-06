# CUSTOM TOOL — R20 approval required; runs from a permitted admin client only.
# No external modules, no credential collection, no data download.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][ValidateSet('DnsAudit','DnsWatch','DnsRecover','FirewallAudit')][string]$Mode,
  [Parameter(Mandatory=$true)][string]$DnsHost,
  [Parameter(Mandatory=$true)][string]$FirewallHost,
  [Parameter(Mandatory=$true)][string]$SshUser,
  [ValidateRange(30,3600)][int]$IntervalSeconds=60
)
$ErrorActionPreference='Stop'
if (-not (Get-Command ssh.exe -ErrorAction SilentlyContinue)) { throw 'OpenSSH client (ssh.exe) is required.' }
$hostName = if ($Mode -like 'Dns*') { $DnsHost } else { $FirewallHost }
if ($hostName -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]{0,252}$' -or $SshUser -notmatch '^[a-zA-Z_][a-zA-Z0-9_.-]*$') { throw 'Invalid host/user format.' }
Write-Host 'Custom tool: run only after TCDC staff approval. Confirm authorized target and hands-on period.'
$remote = switch ($Mode) {
 DnsAudit {'sudo bash /usr/local/sbin/tcdc_dns.sh audit'}
 DnsWatch {"sudo bash /usr/local/sbin/tcdc_dns.sh watch $IntervalSeconds"}
 DnsRecover {'sudo bash /usr/local/sbin/tcdc_dns.sh recover'}
 FirewallAudit {'sudo sh /usr/local/sbin/tcdc_opnsense.sh audit'}
}
Write-Host "Connecting to $hostName. Output contains live incident information: do not publish or export."
& ssh.exe -o BatchMode=yes -o StrictHostKeyChecking=yes "$SshUser@$hostName" $remote
if ($LASTEXITCODE -ne 0) { throw "SSH/remote command failed ($LASTEXITCODE). Ensure reviewed scripts are installed on permitted hosts and SSH keys are configured." }
