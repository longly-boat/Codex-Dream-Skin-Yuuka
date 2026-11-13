param([string]$Root = (Join-Path $PSScriptRoot '..'))
$ErrorActionPreference = 'Stop'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  (Join-Path $Root 'scripts\start-dream-skin.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw $errors }
$definition = $ast.Find({ param($n)
  $n -is [Management.Automation.Language.FunctionDefinitionAst] -and
  $n.Name -eq 'Assert-DreamSkinOfficialProfileLaunchReady'
}, $true)
. ([scriptblock]::Create($definition.Extent.Text))
function Get-DreamSkinRegisteredCodexInstalls { return $script:registered }
function Test-DreamSkinPathEqual { param($Left, $Right); return $Left -ieq $Right }
function Get-DreamSkinRegisteredCodexProcessSnapshot {
  param($RegisteredInstalls, $ExpectedSessionId)
  if ($ExpectedSessionId -ne 7) { throw 'Session binding lost' }
  if ($script:inspectionFails) { throw 'Inspection failed' }
  return @{ TargetProcesses = $script:processes }
}
function Assert-Rejected([string]$Pattern) {
  $failure = $null
  try { Assert-DreamSkinOfficialProfileLaunchReady -Codex $script:selected -ExpectedSessionId 7 }
  catch { $failure = $_ }
  if (-not $failure -or $failure.Exception.Message -notlike $Pattern) {
    throw "Expected rejection: $Pattern; got $failure"
  }
}
$script:processes = @(); $script:inspectionFails = $false
foreach ($version in @('26.1103.7773.0', '99.1234.5678.9')) {
  $script:selected = [pscustomobject]@{
    PackageFullName = "OpenAI.Codex_${version}_x64__2p2nqsd0c76g0"
    Executable = "C:\WindowsApps\Codex_$version\app\ChatGPT.exe"
  }
  $script:registered = @($script:selected)
  Assert-DreamSkinOfficialProfileLaunchReady -Codex $script:selected -ExpectedSessionId 7
}
$valid = $script:selected
$script:registered = @()
Assert-Rejected '*registered Codex package changed*'
$script:registered = @([pscustomobject]@{ PackageFullName = $valid.PackageFullName; Executable = 'C:\Other\ChatGPT.exe' })
Assert-Rejected '*registered Codex package changed*'
$script:registered = @([pscustomobject]@{ PackageFullName = 'OpenAI.Codex_99.1234.5679.0_x64__2p2nqsd0c76g0'; Executable = $valid.Executable })
Assert-Rejected '*registered Codex package changed*'
$script:registered = @($valid)
$script:processes = @(@{ ProcessId = 123 })
Assert-Rejected 'Quit Codex*'
$script:processes = @(); $script:inspectionFails = $true
Assert-Rejected 'Inspection failed'
$script:inspectionFails = $false
foreach ($name in @('OpenAI.Codex_99.1234.5678.9_x64__otherpublisher', 'OpenAI.Codex_fixture')) {
  $script:selected = [pscustomobject]@{ PackageFullName = $name; Executable = $valid.Executable }
  $script:registered = @($script:selected)
  Assert-Rejected '*package identity is not supported*'
}
Write-Output 'PASS: discovered versions accepted; publisher, package/path changes, live processes and inspection failures rejected.'
