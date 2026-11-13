param([string]$Root=(Join-Path $PSScriptRoot '..'))
$ErrorActionPreference='Stop'
. (Join-Path $Root 'scripts\common-windows.ps1')
$times=@()
1..3 | ForEach-Object { $clock=[Diagnostics.Stopwatch]::StartNew(); $native=@(Get-DreamSkinPortListeners -Port 9335); $times+=$clock.ElapsedMilliseconds }
$legacy=@(Get-NetTCPConnection -State Listen -LocalPort 9335 -ErrorAction SilentlyContinue)
$a=@($native|ForEach-Object { "$($_.LocalAddress):$($_.LocalPort):$($_.OwningProcess)" }|Sort-Object)
$b=@($legacy|ForEach-Object { "$($_.LocalAddress):$($_.LocalPort):$($_.OwningProcess)" }|Sort-Object)
if (($a -join ',') -cne ($b -join ',')) {throw 'Native and CIM listener evidence differ'}
foreach($address in @([Net.IPAddress]::Loopback,[Net.IPAddress]::IPv6Loopback)) {
  $listener=[Net.Sockets.TcpListener]::new($address,0)
  try {
    $listener.Start(); $port=$listener.LocalEndpoint.Port
    $found=@(Get-DreamSkinPortListeners -Port $port)
    if(-not ($found|Where-Object { $_.LocalAddress -eq $address.ToString() -and $_.OwningProcess -eq $PID })) { throw 'Own loopback listener missing or wrong PID' }
  } finally { $listener.Stop() }
  if(@(Get-DreamSkinPortListeners -Port $port | Where-Object { $_.OwningProcess -eq $PID }).Count -gt 0){throw 'Closed listener was cached'}
}
Write-Output ('PASS: IPv4/IPv6 PID parity, closed-listener freshness. Timings ms: '+($times -join ','))
