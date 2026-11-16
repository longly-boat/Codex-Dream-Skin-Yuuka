[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Root)
$ErrorActionPreference = 'Stop'
. (Join-Path $Root 'scripts\common-windows.ps1')
. (Join-Path $Root 'scripts\theme-windows.ps1')
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  (Join-Path $Root 'scripts\auto-launch-dream-skin.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw $errors[0].Message }
foreach ($name in @('Assert-DreamSkinAutoLaunchPlainFile', 'Read-DreamSkinAutoLaunchOutputTail',
  'Invoke-DreamSkinAutoLaunchStartAttempt', 'Invoke-DreamSkinAutoLaunchStarter')) {
  $definition = $ast.Find({param($n)
    $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name
  }, $true)
  . ([scriptblock]::Create($definition.Extent.Text))
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('dreamskin lock retry ' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $fixture
$powershell = (Get-Command powershell.exe -ErrorAction Stop).Source
$commonPath = (Join-Path $Root 'scripts\common-windows.ps1').Replace("'", "''")
$childSource = @'
param([switch]$AutoRestartStock, [string]$AutoRestartReservationToken,
  [switch]$RequireUnpaused, [int]$OperationLockTimeoutMilliseconds, [string]$ResultToken)
$ErrorActionPreference = 'Stop'
. 'COMMON_PATH'
$mode = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'mode.txt'))
$callsPath = Join-Path $PSScriptRoot 'calls.txt'
[IO.File]::AppendAllText($callsPath, "$AutoRestartReservationToken $ResultToken`n")
$calls = @(Get-Content -LiteralPath $callsPath).Count
if (-not $AutoRestartStock -or -not $RequireUnpaused) { exit 99 }
$category = 'operation-lock-busy'; $recovery = 'not-needed'; $outcome = 'failure'; $exitCode = 1
if ($mode -eq 'real-lock') {
  $lockName = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'mutex.txt'))
  $mutex = [Threading.Mutex]::new($false, $lockName)
  $owned = $false
  try {
    $started = [Threading.EventWaitHandle]::OpenExisting($lockName + '.Started')
    try { [void]$started.Set() } finally { $started.Dispose() }
    $owned = $mutex.WaitOne($OperationLockTimeoutMilliseconds)
    if ($owned) {
      [IO.File]::AppendAllText((Join-Path $PSScriptRoot 'actions.txt'), "restart`n")
      $category = 'none'; $outcome = 'success'; $exitCode = 0
    }
  } finally {
    if ($owned) { $mutex.ReleaseMutex() }; $mutex.Dispose()
  }
} elseif ($mode -eq 'success' -or ($mode -eq 'busy-success' -and $calls -gt 1)) {
  $category = 'none'; $outcome = 'success'; $exitCode = 0
} elseif ($mode -eq 'terminal' -or ($mode -eq 'busy-terminal' -and $calls -gt 1)) {
  $category = 'internal-start-failure'
} elseif ($mode -eq 'recovery') { $recovery = 'retained' }
$result = [ordered]@{schemaVersion=1;token=$ResultToken;outcome=$outcome;category=$category;appearanceRecovery=$recovery}
$resultPath = Get-DreamSkinStartResultPath -StateRoot $PSScriptRoot -Token $ResultToken
if ($mode -eq 'wrong-token') { $result.token = '00000000000000000000000000000000' }
if ($mode -eq 'unknown') { $result.category = 'unknown' }
if ($mode -eq 'malformed') { [IO.File]::WriteAllText($resultPath, '{') }
elseif ($mode -eq 'oversized') { [IO.File]::WriteAllText($resultPath, ('x' * 4097)) }
elseif ($mode -ne 'missing') { [IO.File]::WriteAllText($resultPath, ($result | ConvertTo-Json -Compress)) }
if ($mode -eq 'busy-stop') { [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'auto-launch.stop'), '') }
if ($mode -eq 'busy-pause') { [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'paused'), '') }
if ($mode -eq 'contradictory-success') { exit 0 }
exit $exitCode
'@
$childSource = $childSource.Replace('COMMON_PATH', $commonPath)
$holder = $null; $pending = $null; $ready = $null; $release = $null; $started = $null
try {
  $cases = @(
    @{Mode='success'; Calls=1; Exit=0}, @{Mode='busy-success'; Calls=2; Exit=0},
    @{Mode='busy-always'; Calls=4; Exit=1}, @{Mode='busy-terminal'; Calls=2; Exit=1},
    @{Mode='terminal'; Calls=1; Exit=1}, @{Mode='recovery'; Calls=1; Exit=1},
    @{Mode='missing'; Calls=1; Exit=1}, @{Mode='malformed'; Calls=1; Exit=1},
    @{Mode='wrong-token'; Calls=1; Exit=1}, @{Mode='unknown'; Calls=1; Exit=1},
    @{Mode='oversized'; Calls=1; Exit=1}, @{Mode='contradictory-success'; Calls=1; Exit=0},
    @{Mode='busy-stop'; Calls=1; Exit=1}, @{Mode='busy-pause'; Calls=1; Exit=1},
    @{Mode='real-lock'; Calls=2; Exit=0}
  )
  foreach ($case in $cases) {
    $caseRoot = Join-Path $fixture $case.Mode
    $null = New-Item -ItemType Directory -Path $caseRoot
    $launcher = Join-Path $caseRoot 'launcher.ps1'
    [IO.File]::WriteAllText($launcher, $childSource, [Text.UTF8Encoding]::new($true))
    [IO.File]::WriteAllText((Join-Path $caseRoot 'mode.txt'), $case.Mode)
    if ($case.Mode -eq 'real-lock') {
      $mutexName = 'Local\DreamSkin.LockRetryTest.' + [guid]::NewGuid().ToString('N')
      [IO.File]::WriteAllText((Join-Path $caseRoot 'mutex.txt'), $mutexName)
      $ready = [Threading.ManualResetEvent]::new($false)
      $release = [Threading.ManualResetEvent]::new($false)
      $started = [Threading.EventWaitHandle]::new($false, [Threading.EventResetMode]::ManualReset, $mutexName + '.Started')
      $holder = [PowerShell]::Create()
      $null = $holder.AddScript({param($name, $ready, $release, $started)
        $mutex = [Threading.Mutex]::new($false, $name)
        $owned = $false
        try {
          $owned = $mutex.WaitOne(5000)
          if (-not $owned) { throw 'Fixture did not acquire its own mutex.' }
          [void]$ready.Set()
          if ([Threading.WaitHandle]::WaitAny(@($started, $release), 30000) -ne 0) {
            throw 'Fixture child did not reach the lock wait.'
          }
          [void]$release.WaitOne(17000)
        } finally { if ($owned) { $mutex.ReleaseMutex() }; $mutex.Dispose() }
      }).AddArgument($mutexName).AddArgument($ready).AddArgument($release).AddArgument($started)
      $pending = $holder.BeginInvoke()
      if (-not $ready.WaitOne(5000)) { throw 'Fixture lock did not become ready.' }
    }
    $reservation = [guid]::NewGuid().ToString('N')
    $result = Invoke-DreamSkinAutoLaunchStarter -PowerShellPath $powershell -StartScript $launcher `
      -StateRoot $caseRoot -AutoRestartReservationToken $reservation -OperationLockTimeoutMilliseconds 15000
    if (-not (Test-Path -LiteralPath (Join-Path $caseRoot 'calls.txt'))) {
      throw "Fixture launcher did not execute: $($result.Output -join ' ')"
    }
    $calls = @(Get-Content -LiteralPath (Join-Path $caseRoot 'calls.txt'))
    if ($calls.Count -ne $case.Calls -or $result.ExitCode -ne $case.Exit) {
      throw "Wrong retry behavior for $($case.Mode): calls=$($calls.Count), exit=$($result.ExitCode); $($result.Output -join ' ')"
    }
    $nonces = @($calls | ForEach-Object {
      $pair = $_.Split(' ')
      if ($pair[0] -cne $reservation) { throw 'A lock retry replaced its one-shot reservation.' }
      $pair[1]
    })
    if (@($nonces | Select-Object -Unique).Count -ne $calls.Count) { throw 'Result nonce was reused.' }
    if (@(Get-ChildItem -LiteralPath $caseRoot -Filter '.start-result-*.json').Count) { throw 'Child result was not cleaned up.' }
    if ($case.Mode -eq 'real-lock') {
      if (@(Get-Content -LiteralPath (Join-Path $caseRoot 'actions.txt')).Count -ne 1) { throw 'Contention caused duplicate actions.' }
      $null = $holder.EndInvoke($pending)
      $holder.Dispose(); $holder = $null; $ready.Dispose(); $release.Dispose(); $started.Dispose()
    }
  }
  # The common busy category must never escape as retryable after any earlier
  # acquisition, even if foreground recovery has since released the mutex.
  $startSource = [IO.File]::ReadAllText((Join-Path $Root 'scripts\start-dream-skin.ps1'))
  if (-not $startSource.Contains("`$reportedCategory -ceq 'operation-lock-busy' -and `$hasAcquiredOperationLock") -or
    -not $startSource.Contains("`$hasAcquiredOperationLock = `$true")) {
    throw 'Post-lock failure classification lacks the acquisition-history guard.'
  }
  Write-Output 'PASS: 15 lock retry cases, including a real 17-second lock; one reservation, one action, bounded attempts and fail-closed results.'
} finally {
  if ($null -ne $holder) {
    [void]$release.Set(); $null = $holder.EndInvoke($pending)
    $holder.Dispose(); $ready.Dispose(); $release.Dispose(); $started.Dispose()
  }
  $resolved = [IO.Path]::GetFullPath($fixture)
  if (-not $resolved.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing cleanup outside the temporary fixture root.'
  }
  Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
}
