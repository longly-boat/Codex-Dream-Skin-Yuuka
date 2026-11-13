[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Root)
$ErrorActionPreference = 'Stop'
. (Join-Path $Root 'scripts\common-windows.ps1')
$script:install = [pscustomobject]@{
  Executable = 'C:\SyntheticPackage\app\ChatGPT.exe'
  PackageFullName = 'OpenAI.Codex_1.0.0.0_x64__test'
  PackageFamilyName = 'OpenAI.Codex_test'
}
$script:epoch = [DateTime]::Parse('2026-11-09T12:00:00Z').ToUniversalTime()
function New-Row([int]$ProcessId, [string]$Arguments = '', [int]$Session = 7) {
  [pscustomobject]@{ ProcessId=$ProcessId; SessionId=$Session; ExecutablePath=$script:install.Executable
    CommandLine=('"'+$script:install.Executable+'" '+$Arguments) }
}
function Set-Fixture($Before,$After,[switch]$Reuse) {
  $script:before=@($Before); $script:after=@($After); $script:cimCalls=0
  $script:processCalls=@{}; $script:reuse=[bool]$Reuse; $script:lookedUp=@()
}
function Get-CimInstance {
  [CmdletBinding()] param($ClassName,$Filter)
  if ($ClassName -ne 'Win32_Process' -or $Filter -ne "Name = 'ChatGPT.exe'") { throw "Unexpected CIM query: $Filter" }
  $script:cimCalls++
  if ($script:cimCalls -eq 1) { return $script:before }
  return $script:after
}
function Get-Process {
  [CmdletBinding()] param($Id)
  $script:lookedUp += [int]$Id
  if (-not $script:processCalls.ContainsKey([int]$Id)) { $script:processCalls[[int]$Id]=0 }
  $script:processCalls[[int]$Id]++
  $start=$script:epoch
  if ($script:reuse -and $script:processCalls[[int]$Id] -gt 1) { $start=$start.AddSeconds(1) }
  $p=[pscustomobject]@{StartTime=$start;SessionId=7}
  $p | Add-Member -MemberType ScriptMethod -Name Dispose -Value {}
  return $p
}
function Get-DreamSkinProcessExecutablePath { param($ProcessInfo) return $ProcessInfo.ExecutablePath }
function Snapshot { Get-DreamSkinRegisteredCodexProcessSnapshot -RegisteredInstalls @($script:install) -ExpectedSessionId 7 -MainProcessOnly }
function Reject([string]$Label,[scriptblock]$Action) {
  $rejected=$false
  try { & $Action | Out-Null } catch { $rejected=$true }
  if (-not $rejected) { throw "Expected rejection: $Label" }
}
$main=New-Row 100
$child=New-Row 101 '--type=renderer'
$gpu=New-Row 102 '--type=gpu-process'
Set-Fixture @($main,$child) @($main,$gpu)
$result=Snapshot
if (@($result.TargetProcesses).Count -ne 1 -or $result.TargetProcesses[0].processId -ne 100) { throw 'Dynamic children changed the main-process reservation.' }
if (@($script:lookedUp | Where-Object {$_ -ne 100}).Count) { throw 'Child process creation time was read on the main-only path.' }
Set-Fixture @($main,$child) @($main,$gpu)
Reject 'legacy strict snapshot still rejects changed complete process sets' {
  Get-DreamSkinRegisteredCodexProcessSnapshot -RegisteredInstalls @($script:install) -ExpectedSessionId 7
}
Set-Fixture @($main) @($main) -Reuse
Reject 'main PID reuse' { Snapshot }
Set-Fixture @($main) @((New-Row 200))
Reject 'replacement main PID' { Snapshot }
Set-Fixture @($main,(New-Row 200)) @($main)
Reject 'multiple initial mains' { Snapshot }
Set-Fixture @($main) @($main,(New-Row 200))
Reject 'new main appears during capture' { Snapshot }
$blank=New-Row 100; $blank.CommandLine=''
Set-Fixture @($blank) @($main)
Reject 'unreadable initial command' { Snapshot }
Set-Fixture @($main) @($blank)
Reject 'unreadable confirmation command' { Snapshot }
$changed=New-Row 100; $changed.ExecutablePath='C:\DifferentPackage\app\ChatGPT.exe'
Set-Fixture @($main) @($changed)
Reject 'main executable path changed' { Snapshot }
Set-Fixture @($main,(New-Row 300 '' 8)) @($main,(New-Row 301 '' 8))
$result=Snapshot
if (@($result.TargetProcesses).Count -ne 1) { throw 'Another Windows session entered the main reservation.' }
Set-Fixture @($main,(New-Row 101 '"--type=renderer"')) @($main,(New-Row 102 '--type utility'))
$result=Snapshot
if (@($result.TargetProcesses).Count -ne 1) { throw 'Quoted or split type flags were classified as a main process.' }
Write-Output 'PASS: main-process snapshots tolerate child churn and reject reused, replaced, ambiguous, or unreadable main identities.'

# Exercise the real bound shutdown path: only the verified main receives close.
# A new child survives in the inventory, for the launcher's separate stable-zero
# check to handle; it must never be widened into a shutdown target.
function Get-DreamSkinRegisteredCodexInstalls { return @($script:install) }
function Assert-DreamSkinAutoRestartControlClear { param($StateRoot) }
$script:mainClosed=$false
$script:closeCalls=@()
function Get-CimInstance {
  [CmdletBinding()] param($ClassName,$Filter)
  if ($Filter -ne "Name = 'ChatGPT.exe'") { throw "Unexpected shutdown query: $Filter" }
  if (-not $script:mainClosed) { New-Row 100 }
  New-Row 400 '--type=renderer'
}
function Get-Process {
  [CmdletBinding()] param($Id)
  if ([int]$Id -ne 100) { throw 'Shutdown tried to open a child process.' }
  $p=[pscustomobject]@{ StartTime=$script:epoch;SessionId=7;MainWindowHandle=123;HasExited=$false;Id=100 }
  $p | Add-Member -MemberType ScriptMethod -Name Dispose -Value {}
  $p | Add-Member -MemberType ScriptMethod -Name CloseMainWindow -Value {
    $script:closeCalls += $this.Id
    $script:mainClosed=$true
    return $true
  }
  return $p
}
function Stop-Process { [CmdletBinding()] param($InputObject,[switch]$Force) throw 'Unexpected force-stop during graceful main shutdown.' }
$reserved=Snapshot
Stop-DreamSkinCodex -Codex $script:install -ExpectedAutoRestartTargets @($reserved.TargetProcesses) -AutoRestartStateRoot 'C:\SyntheticState' -MainProcessOnly
if (($script:closeCalls -join ',') -ne '100') { throw 'Bound shutdown did not exclusively close the reserved main.' }
Write-Output 'PASS: graceful bound shutdown never targets dynamically added child processes.'
# A successful close that hides to tray can proceed immediately to the exact
# main-process force gate; it must not touch the live renderer or wait 3s.
$script:mainClosed=$false
$script:hiddenToTray=$false
$script:forceCalls=@()
$script:sleeps=@()
function Start-Sleep { param($Milliseconds,$Seconds) $script:sleeps += $Milliseconds }
function Get-Process {
  [CmdletBinding()] param($Id)
  if ([int]$Id -ne 100) { throw 'Tray fast path opened a child.' }
  $p=[pscustomobject]@{StartTime=$script:epoch;SessionId=7;MainWindowHandle=$(if($script:hiddenToTray){[IntPtr]::Zero}else{[IntPtr]123});HasExited=$false;Id=100}
  $p | Add-Member ScriptMethod Dispose {}
  $p | Add-Member ScriptMethod CloseMainWindow { $script:hiddenToTray=$true;return $true }
  $p | Add-Member ScriptMethod WaitForExit { param($timeout) return $true }
  return $p
}
function Stop-Process {
  [CmdletBinding()] param($InputObject,[switch]$Force)
  if($InputObject.Id -ne 100 -or -not $script:hiddenToTray){throw 'Unsafe tray force target'}
  $script:forceCalls += $InputObject.Id
  $script:mainClosed=$true
}
$reserved=Snapshot
Stop-DreamSkinCodex -Codex $script:install -ExpectedAutoRestartTargets @($reserved.TargetProcesses) -AutoRestartStateRoot 'C:\SyntheticState' -MainProcessOnly -AllowForce
if(($script:forceCalls -join ',') -ne '100' -or $script:sleeps.Count -ne 0){throw 'Tray fast path did not exclusively stop main without grace sleeps'}
Write-Output 'PASS: hidden-to-tray main skips idle grace, retains exact force gate, and preserves children.'
# The optimized entry must still detect an additional main process at the
# fresh pre-close boundary, before either graceful or forced shutdown.
$script:mainClosed=$false
$script:hiddenToTray=$false
$script:forceCalls=@()
$script:closeCalls=@()
function Get-CimInstance {
  [CmdletBinding()] param($ClassName,$Filter)
  New-Row 100
  New-Row 200
}
Reject 'second main at the actual close boundary' {
  Stop-DreamSkinCodex -Codex $script:install -ExpectedAutoRestartTargets @($reserved.TargetProcesses) -AutoRestartStateRoot 'C:\SyntheticState' -MainProcessOnly -AllowForce
}
if($script:hiddenToTray -or $script:forceCalls.Count){throw 'Changed main set was acted upon before rejection'}
$script:emptyReads=0
function Get-CimInstance {
  [CmdletBinding()] param($ClassName,$Filter)
  $script:emptyReads++
  return @()
}
$empty=Get-DreamSkinRegisteredCodexProcessSnapshot -RegisteredInstalls @($script:install) -ExpectedSessionId 7
if($empty.TargetProcesses.Count -ne 0 -or $script:emptyReads -ne 1){throw 'Empty inventory performed redundant identity reads'}
Write-Output 'PASS: optimized close rejects new mains before action; empty snapshot uses one fresh inventory.'
