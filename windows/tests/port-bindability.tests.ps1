param([string]$Root = (Join-Path $PSScriptRoot '..'))
$ErrorActionPreference = 'Stop'
. (Join-Path $Root 'scripts\common-windows.ps1')
& {
  function Get-DreamSkinPortListeners { param($Port); return @() }
  function Test-DreamSkinLoopbackPortBindable { param($Port); return $Port -eq 9390 }
  if (Test-DreamSkinPortAvailable -Port 9335) { throw 'No-listener reserved port was treated as available' }
  if ((Resolve-DreamSkinStartPort -Port 9335 -PortExplicit $false) -ne 9390) { throw 'Reserved range was not skipped' }
}
$probe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
try {
  $probe.Server.ExclusiveAddressUse = $true
  $probe.Start()
  $port = [int]$probe.LocalEndpoint.Port
  if (Test-DreamSkinLoopbackPortBindable -Port $port) { throw 'Live exclusive listener was treated as bindable' }
} finally { $probe.Stop() }
if (-not (Test-DreamSkinLoopbackPortBindable -Port $port)) { throw 'Released port could not be bound' }
if (-not (Test-DreamSkinLoopbackPortBindable -Port $port)) { throw 'Probe leaked its socket' }
$selected = Select-DreamSkinPort -PreferredPort 9335
if (-not (Test-DreamSkinPortAvailable -Port $selected)) { throw 'Selected port is not bindable' }
Write-Output "PASS: reserved ports skipped, occupied port rejected, probe released; actual selected port=$selected."
