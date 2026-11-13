param([string]$Root = (Join-Path $PSScriptRoot '..'))
$ErrorActionPreference = 'Stop'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('dreamskin hidden ' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $fixture
try {
  $exe = Join-Path $fixture 'auto-launch-hidden.exe'
  $source = [IO.Path]::GetFullPath((Join-Path $Root 'scripts\auto-launch-hidden.cs'))
  if ($PSVersionTable.PSEdition -eq 'Core') {
    # PowerShell 7 Add-Type cannot emit executable assemblies. Compile the
    # real .NET Framework GUI launcher with the same Windows compiler used
    # by installation, then retain all launch/PE checks in this test host.
    $compileScript = Join-Path $fixture 'compile-bootstrap.ps1'
    [IO.File]::WriteAllText($compileScript, @'
param([string]$Source, [string]$Destination)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition ([IO.File]::ReadAllText($Source)) -OutputAssembly $Destination -OutputType WindowsApplication
'@)
    $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $windowsPowerShell -NoProfile -ExecutionPolicy RemoteSigned -File $compileScript -Source $source -Destination $exe
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'GUI bootstrap compilation failed.' }
  } else {
    Add-Type -TypeDefinition ([IO.File]::ReadAllText($source)) -OutputAssembly $exe -OutputType WindowsApplication
  }
  $probe = @'
param([switch]$TakeOverStartupSession)
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class ConsoleProbe { [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); }'
@{ console = [ConsoleProbe]::GetConsoleWindow().ToInt64(); takeover = [bool]$TakeOverStartupSession } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'result.json')
'@
  [IO.File]::WriteAllText((Join-Path $fixture 'auto-launch-dream-skin.ps1'), $probe)
  $process = Start-Process -FilePath $exe -WindowStyle Hidden -PassThru
  if (-not $process.WaitForExit(10000) -or $process.ExitCode -ne 0) { throw 'Bootstrap failed' }
  $deadline = [DateTime]::UtcNow.AddSeconds(15)
  $resultPath = Join-Path $fixture 'result.json'
  while (-not (Test-Path -LiteralPath $resultPath) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
  $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
  if ($result.console -ne 0 -or -not $result.takeover) { throw 'Watcher acquired a console or lost startup takeover flag' }
  # Check the executable PE subsystem is Windows GUI (2), not console (3).
  $bytes = [IO.File]::ReadAllBytes($exe)
  $pe = [BitConverter]::ToInt32($bytes, 0x3c)
  if ([BitConverter]::ToUInt16($bytes, $pe + 24 + 68) -ne 2) { throw 'Bootstrap is not a GUI executable' }
  Write-Output 'PASS: GUI bootstrap starts PowerShell without a console, preserving startup takeover and paths with spaces.'
} finally {
  # Exact generated test directory only; no production files or processes.
  if ([IO.Path]::GetFullPath($fixture).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue
  }
}
