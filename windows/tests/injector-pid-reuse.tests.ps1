[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Root)
$ErrorActionPreference = 'Stop'
. (Join-Path $Root 'scripts\common-windows.ps1')
$fixtureProcess = Start-Process -FilePath (Get-Command powershell.exe).Source `
  -ArgumentList '-NoProfile -NonInteractive -Command "Start-Sleep -Seconds 45"' -WindowStyle Hidden -PassThru
$null = $fixtureProcess.Handle
try {
  $actualStart = $fixtureProcess.StartTime.ToUniversalTime()
  $state = [pscustomobject]@{
    injectorPid = $fixtureProcess.Id
    injectorStartedAt = $actualStart.AddDays(-1).ToString('o')
    injectorPath = (Join-Path $Root 'scripts\injector.mjs')
    nodePath = (Join-Path $Root 'runtime\node\node.exe')
    port = 9335; browserId = 'fixture-browser'; skillRoot = $null
  }
  $result = Stop-DreamSkinRecordedInjector -State $state
  if ($result -ne $false -or $fixtureProcess.HasExited) {
    throw 'A reused PID was stopped or did not mark its old state stale.'
  }
  foreach ($expected in @($actualStart.ToString('o'), 'invalid-time', $actualStart.ToString('o').TrimEnd('Z'), $null)) {
    $state.injectorStartedAt = $expected
    $rejected = $false
    try { $null = Stop-DreamSkinRecordedInjector -State $state } catch { $rejected = $true }
    if (-not $rejected -or $fixtureProcess.HasExited) {
      throw 'An uncertain or same-start mismatched identity did not fail closed.'
    }
  }
  Write-Output 'PASS: a proven reused injector PID is preserved and marked stale; invalid, missing and same-time mismatched identities remain protected.'
} finally {
  if (-not $fixtureProcess.HasExited) { Stop-Process -InputObject $fixtureProcess -Force }
  $fixtureProcess.Dispose()
}

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('dreamskin injector identity ' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $fixtureRoot
$nodeProcess = $null
try {
  $injector = Join-Path $fixtureRoot 'injector.mjs'
  [IO.File]::WriteAllText($injector, 'setInterval(() => {}, 1000);')
  $nodePath = (Get-Command node.exe -ErrorAction Stop).Source
  $arguments = (ConvertTo-DreamSkinProcessArgument -Value $injector) + ' --watch --port 9335 --browser-id fixture-browser'
  $nodeProcess = Start-Process -FilePath $nodePath -ArgumentList $arguments -WindowStyle Hidden -PassThru
  $null = $nodeProcess.Handle
  $state = [pscustomobject]@{
    injectorPid = $nodeProcess.Id; injectorStartedAt = $nodeProcess.StartTime.ToUniversalTime().ToString('o')
    injectorPath = $injector; nodePath = $nodePath; port = 9335; browserId = 'wrong-browser'; skillRoot = $null
  }
  $rejected = $false
  try { $null = Stop-DreamSkinRecordedInjector -State $state } catch { $rejected = $true }
  if (-not $rejected -or $nodeProcess.HasExited) { throw 'Same-start wrong Browser ID was not protected.' }
  $state.browserId = 'fixture-browser'
  if (-not (Stop-DreamSkinRecordedInjector -State $state) -or -not $nodeProcess.WaitForExit(1000)) {
    throw 'The exact recorded test injector was not stopped.'
  }
  Write-Output 'PASS: matching creation time still requires exact watcher arguments; the verified test injector can be stopped.'
} finally {
  if ($null -ne $nodeProcess) {
    if (-not $nodeProcess.HasExited) { Stop-Process -InputObject $nodeProcess -Force }
    $nodeProcess.Dispose()
  }
  $resolved = [IO.Path]::GetFullPath($fixtureRoot)
  if (-not $resolved.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing cleanup outside the temporary injector fixture.'
  }
  Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
}
