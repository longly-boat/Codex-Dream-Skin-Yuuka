[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Root)
$ErrorActionPreference = 'Stop'
. (Join-Path $Root 'scripts\common-windows.ps1')
. (Join-Path $Root 'scripts\theme-windows.ps1')
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  (Join-Path $Root 'scripts\auto-launch-dream-skin.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw $errors[0].Message }
foreach ($name in @('Assert-DreamSkinAutoLaunchPlainFile', 'Read-DreamSkinAutoLaunchOutputTail', 'Invoke-DreamSkinAutoLaunchStarter')) {
  $definition = $ast.Find({param($n)
    $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name
  }, $true)
  . ([scriptblock]::Create($definition.Extent.Text))
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('dreamskin child exit ' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $fixture
$powershell = (Get-Command powershell.exe -ErrorAction Stop).Source
$children = @()
try {
  foreach ($expected in @(0, 7)) {
    $launcher = Join-Path $fixture "launcher $expected.ps1"
    $pidFile = Join-Path $fixture "child-$expected.txt"
    $code = @'
param([switch]$AutoRestartStock, [string]$AutoRestartReservationToken,
  [switch]$RequireUnpaused, [int]$OperationLockTimeoutMilliseconds)
if (-not $AutoRestartStock -or -not $RequireUnpaused -or $OperationLockTimeoutMilliseconds -ne 15000) { exit 99 }
$info = [Diagnostics.ProcessStartInfo]::new()
$info.FileName = (Get-Command powershell.exe).Source
$info.Arguments = '-NoProfile -NonInteractive -Command "Start-Sleep -Seconds 5"'
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
# Inherit this launcher's stdout/stderr and outlive it.
$child = [Diagnostics.Process]::Start($info)
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'child-EXIT_CODE.txt'), "$($child.Id)")
Write-Output 'fixture-launcher-finished'
exit EXIT_CODE
'@
    [IO.File]::WriteAllText($launcher, $code.Replace('EXIT_CODE', "$expected"), [Text.UTF8Encoding]::new($true))
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $result = Invoke-DreamSkinAutoLaunchStarter -PowerShellPath $powershell -StartScript $launcher `
      -StateRoot $fixture -AutoRestartReservationToken ([guid]::NewGuid().ToString('N')) `
      -OperationLockTimeoutMilliseconds 15000
    if ($result.ExitCode -ne $expected -or $clock.ElapsedMilliseconds -ge 4000) {
      throw "Launcher exit code or bounded return failed: $($result.ExitCode), $($clock.ElapsedMilliseconds) ms; $($result.Output -join ' ')"
    }
    $child = Get-Process -Id ([int][IO.File]::ReadAllText($pidFile)) -ErrorAction Stop
    $children += $child
    if ($child.HasExited) { throw 'The launcher helper waited for or terminated the descendant.' }
  }
  $tailPath = Join-Path $fixture 'large-output.log'
  [IO.File]::WriteAllText($tailPath, (('x' * 4096 + "`n") * 50) + 'end-marker')
  $tail = @(Read-DreamSkinAutoLaunchOutputTail -Path $tailPath)
  if (($tail -join "`n").Length -gt 65536 -or $tail[-1] -ne 'end-marker') {
    throw 'Output was not a bounded tail snapshot.'
  }
  Write-Output 'PASS: launcher exit is independent of inherited descendant pipes; exit codes and bounded output are preserved.'
} finally {
  foreach ($child in $children) { [void]$child.WaitForExit(10000); $child.Dispose() }
  if ([IO.Path]::GetFullPath($fixture).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue
  }
}
