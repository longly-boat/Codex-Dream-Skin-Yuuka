[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Root)
$ErrorActionPreference = 'Stop'

function Read-TestAst {
  param([string]$Path)
  $tokens = $null; $errors = $null
  $ast = [Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
  if ($errors.Count) { throw $errors[0].Message }
  return $ast
}
function Get-ConstantArgument {
  param($Command, [string]$Name)
  $elements = @($Command.CommandElements)
  for ($i = 0; $i -lt $elements.Count - 1; $i++) {
    if ($elements[$i] -is [Management.Automation.Language.CommandParameterAst] -and
      $elements[$i].ParameterName -eq $Name) {
      return [int]$elements[$i + 1].SafeGetValue()
    }
  }
  throw "Missing bounded lock wait: $Name"
}
$auto = Read-TestAst (Join-Path $Root 'scripts\auto-launch-dream-skin.ps1')
$launcher = $auto.Find({param($n)
  $n -is [Management.Automation.Language.CommandAst] -and
  $n.GetCommandName() -eq 'Invoke-DreamSkinAutoLaunchStarter'
}, $true)
$autoWait = Get-ConstantArgument $launcher 'OperationLockTimeoutMilliseconds'
if ($autoWait -le 0 -or $autoWait -gt 30000) { throw 'Automatic takeover must use a short bounded lock wait.' }
$tray = Read-TestAst (Join-Path $Root 'scripts\tray-dream-skin.ps1')
$trayAssignment = $tray.Find({param($n)
  $n -is [Management.Automation.Language.AssignmentStatementAst] -and
  $n.Left.Extent.Text -eq '$initializationLock'
}, $true)
$trayLock = $trayAssignment.Find({param($n)
  $n -is [Management.Automation.Language.CommandAst] -and
  $n.GetCommandName() -eq 'Enter-DreamSkinOperationLock'
}, $true)
$trayWait = Get-ConstantArgument $trayLock 'TimeoutMilliseconds'
if ($trayWait -lt $autoWait -or $trayWait -gt 60000) { throw 'Tray initialization wait must be bounded and cover automatic startup.' }

# Exercise the real lock implementation against a unique mutex. Do not
# contend with or release the installed user's operation lock during tests.
$common = Read-TestAst (Join-Path $Root 'scripts\common-windows.ps1')
$fixtureName = 'Local\DreamSkin.StartupLockTest.' + [guid]::NewGuid().ToString('N')
foreach ($name in @('Enter-DreamSkinOperationLock', 'Exit-DreamSkinOperationLock')) {
  $definition = $common.Find({param($n)
    $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name
  }, $true)
  $source = $definition.Extent.Text.Replace('Global\CodexDreamSkin.$sid.Operation', $fixtureName)
  . ([scriptblock]::Create($source))
}
foreach ($persistent in @($false, $true)) {
  $ready = [Threading.ManualResetEvent]::new($false)
  $release = [Threading.ManualResetEvent]::new($false)
  $holder = [PowerShell]::Create()
  $null = $holder.AddScript({
    param($name, $ready, $release, $persistent)
    $mutex = [Threading.Mutex]::new($false, $name)
    $owned = $false
    try {
      $owned = $mutex.WaitOne(5000)
      if (-not $owned) { throw 'Fixture could not acquire lock.' }
      [void]$ready.Set()
      [void]$release.WaitOne($(if ($persistent) { 5000 } else { 400 }))
    } finally {
      if ($owned) { $mutex.ReleaseMutex() }
      $mutex.Dispose()
    }
  }).AddArgument($fixtureName).AddArgument($ready).AddArgument($release).AddArgument($persistent)
  $pending = $holder.BeginInvoke()
  $lock = $null
  try {
    if (-not $ready.WaitOne(5000)) { throw 'Lock fixture did not become ready.' }
    if (-not $persistent) {
      $rejected = $false
      try { $lock = Enter-DreamSkinOperationLock } catch { $rejected = $true }
      if (-not $rejected) { throw 'An immediate contender acquired another owner lock.' }
      $clock = [Diagnostics.Stopwatch]::StartNew()
      $lock = Enter-DreamSkinOperationLock -TimeoutMilliseconds $autoWait
      if ($clock.ElapsedMilliseconds -gt 4000) { throw 'Lock did not wake promptly when the owner released it.' }
    } else {
      $rejected = $false
      $clock = [Diagnostics.Stopwatch]::StartNew()
      try { $lock = Enter-DreamSkinOperationLock -TimeoutMilliseconds 100 } catch { $rejected = $true }
      if (-not $rejected -or $clock.ElapsedMilliseconds -gt 2000) {
        throw 'Persistent contention must fail within its bounded wait without stealing the lock.'
      }
    }
  } finally {
    if ($null -ne $lock) { Exit-DreamSkinOperationLock -Mutex $lock }
    [void]$release.Set()
    $null = $holder.EndInvoke($pending)
    $holder.Dispose(); $ready.Dispose(); $release.Dispose()
  }
}
$clock = [Diagnostics.Stopwatch]::StartNew()
$lock = Enter-DreamSkinOperationLock -TimeoutMilliseconds $autoWait
try {
  if ($clock.ElapsedMilliseconds -gt 500) { throw 'An uncontended lock added a startup delay.' }
} finally { Exit-DreamSkinOperationLock -Mutex $lock }
Write-Output 'PASS: login lock contention resumes on release, remains bounded, and adds no fixed startup delay.'
