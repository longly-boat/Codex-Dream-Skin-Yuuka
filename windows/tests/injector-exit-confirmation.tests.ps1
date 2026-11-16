[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Root,
  # Optional local negative control. CI always exercises the current source;
  # an external historical source file requires no git history or tag lookup.
  [string]$StopImplementationPath,
  [switch]$ExpectLegacyFailure
)
$ErrorActionPreference = 'Stop'
. (Join-Path $Root 'scripts\common-windows.ps1')
if (-not $StopImplementationPath) {
  $StopImplementationPath = Join-Path $Root 'scripts\common-windows.ps1'
}
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
  $StopImplementationPath, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw $errors[0].Message }
$definition = $ast.Find({param($n)
  $n -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $n.Name -eq 'Stop-DreamSkinRecordedInjector'
}, $true)
if ($null -eq $definition) { throw 'The injector stop implementation was not found.' }
$stopSource = $definition.Extent.Text
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('dreamskin exit confirmation ' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $fixtureRoot
$fixtureProcess = $null
try {
  $nodePath = (Get-Command node.exe -ErrorAction Stop).Source
  $injector = Join-Path $fixtureRoot 'injector.mjs'
  [IO.File]::WriteAllText($injector, 'setInterval(() => {}, 1000);')
  $arguments = (ConvertTo-DreamSkinProcessArgument -Value $injector) + ' --watch --port 49333 --browser-id exit-fixture'
  $modes = if ($ExpectLegacyFailure) { @('stale-cim') } else { @('native', 'stale-cim') }
  foreach ($mode in $modes) {
    $fixtureProcess = Start-Process -FilePath $nodePath -ArgumentList $arguments -WindowStyle Hidden -PassThru
    $null = $fixtureProcess.Handle
    try {
      $state = [pscustomobject]@{
        injectorPid = $fixtureProcess.Id
        injectorStartedAt = $fixtureProcess.StartTime.ToUniversalTime().ToString('o')
        injectorPath = $injector; nodePath = $nodePath
        port = 49333; browserId = 'exit-fixture'; skillRoot = $null
      }
      $snapshot = CimCmdlets\Get-CimInstance Win32_Process -Filter "ProcessId = $($fixtureProcess.Id)" -ErrorAction Stop
      if ($null -eq $snapshot -or -not $snapshot.ExecutablePath -or -not $snapshot.CommandLine) {
        throw 'The test injector did not expose a complete real identity snapshot.'
      }
      # All overrides live only in this child scope. Preserve a real identity
      # snapshot even after the native process exits; never query another PID.
      & {
        param($Fixture, $State, $Snapshot, $Source, $Mode, $Legacy)
        . ([scriptblock]::Create($Source))
        $probe = [pscustomobject]@{ Calls = 0; CommandLine = "$($Snapshot.CommandLine)" }
        if ($Mode -eq 'stale-cim') {
          function Get-CimInstance {
            [CmdletBinding()]
            param([Parameter(Position = 0)][string]$ClassName, [string]$Filter)
            if ($ClassName -cne 'Win32_Process' -or $Filter -cne "ProcessId = $($Fixture.Id)") {
              throw 'The fixture refused an unrelated process query.'
            }
            $probe.Calls++
            return [pscustomobject]@{
              ProcessId = $Snapshot.ProcessId
              ExecutablePath = "$($Snapshot.ExecutablePath)"
              CommandLine = $probe.CommandLine
            }
          }
          foreach ($field in @('browserId', 'port', 'nodePath', 'injectorPath', 'watch')) {
            $original = if ($field -eq 'watch') { $probe.CommandLine } else { $State.$field }
            try {
              if ($field -eq 'watch') { $probe.CommandLine = $original.Replace('--watch', '--once') }
              elseif ($field -eq 'port') { $State.port = 49334 }
              else { $State.$field = "$original-wrong" }
              $rejected = $false
              try { $null = Stop-DreamSkinRecordedInjector -State $State } catch {
                if ($_.Exception.Message -notlike '*visible identity does not match*') { throw }
                $rejected = $true
              }
              if (-not $rejected -or $Fixture.HasExited) {
                throw "A mismatched $field did not preserve the live fixture."
              }
            } finally {
              if ($field -eq 'watch') { $probe.CommandLine = $original } else { $State.$field = $original }
            }
          }
        }
        $probe.Calls = 0
        $stopError = $null; $stopped = $null
        try { $stopped = Stop-DreamSkinRecordedInjector -State $State } catch { $stopError = $_ }
        if ($Legacy) {
          if ($null -eq $stopError -or $stopError.Exception.Message -notlike '*recorded Dream Skin injector did not stop*' -or
            -not $Fixture.WaitForExit(1000) -or $probe.Calls -lt 2) {
            throw 'The legacy negative control did not falsely reject an exited process with a retained CIM record.'
          }
          Write-Output 'PASS: negative control reproduces the legacy false failure after the exact native process exited.'
        } else {
          if ($null -ne $stopError) { throw $stopError }
          if ($stopped -ne $true -or -not $Fixture.WaitForExit(1000)) {
            throw "The exact live injector was not stopped and confirmed in $Mode mode."
          }
          if ($Mode -eq 'stale-cim') {
            # Prove the seam still exposes the stale snapshot after exit.
            $retained = Get-CimInstance Win32_Process -Filter "ProcessId = $($Fixture.Id)"
            if ($null -eq $retained -or $retained.ProcessId -ne $Fixture.Id) {
              throw 'The retained-CIM fixture was not active after process exit.'
            }
          }
          Write-Output "PASS: $Mode exit uses the verified native process; mismatched identities remain protected."
        }
      } $fixtureProcess $state $snapshot $stopSource $mode ([bool]$ExpectLegacyFailure)
    } finally {
      if (-not $fixtureProcess.HasExited) {
        $fixtureProcess.Kill()
        if (-not $fixtureProcess.WaitForExit(5000)) { throw 'Could not clean up the owned injector fixture.' }
      }
      $fixtureProcess.Dispose(); $fixtureProcess = $null
    }
  }

  if (-not $ExpectLegacyFailure) {
    foreach ($mode in @('identity-changed', 'wait-timeout', 'kill-failed', 'already-exited')) {
      & {
        param($Source, $Mode, $NodePath, $Injector)
        . ([scriptblock]::Create($Source))
        $fixtureHandle = [pscustomobject]@{
          StartTime = [DateTime]::UtcNow; HasExited = $false; Mode = $Mode
          HandleReads = 0; Refreshes = 0; Kills = 0; Waits = 0; WaitMilliseconds = 0; Disposes = 0
        }
        $fixtureHandle | Add-Member ScriptProperty Handle { $this.HandleReads++; return [IntPtr]1 }
        $fixtureHandle | Add-Member ScriptMethod Refresh {
          $this.Refreshes++
          if ($this.Mode -eq 'identity-changed') { $this.StartTime = $this.StartTime.AddSeconds(1) }
          if ($this.Mode -eq 'already-exited') { $this.HasExited = $true }
        }
        $fixtureHandle | Add-Member ScriptMethod Kill {
          $this.Kills++
          if ($this.Mode -eq 'kill-failed') { throw 'Fixture kill failed.' }
        }
        $fixtureHandle | Add-Member ScriptMethod WaitForExit {
          param($milliseconds)
          $this.Waits++; $this.WaitMilliseconds = $milliseconds
          return $false
        }
        $fixtureHandle | Add-Member ScriptMethod Dispose { $this.Disposes++ }
        $state = [pscustomobject]@{
          injectorPid = 7654321; injectorStartedAt = $fixtureHandle.StartTime.ToString('o')
          injectorPath = $Injector; nodePath = $NodePath
          port = 49333; browserId = 'exit-fixture'; skillRoot = $null
        }
        function Get-Process {
          [CmdletBinding()]
          param([int]$Id)
          if ($Id -ne $state.injectorPid) { throw 'Unrelated fixture process lookup.' }
          return $fixtureHandle
        }
        function Get-CimInstance {
          [CmdletBinding()]
          param([Parameter(Position = 0)][string]$ClassName, [string]$Filter)
          if ($ClassName -cne 'Win32_Process' -or $Filter -cne "ProcessId = $($state.injectorPid)") {
            throw 'Unrelated fixture CIM lookup.'
          }
          return [pscustomobject]@{
            ProcessId = $state.injectorPid; ExecutablePath = $NodePath
            CommandLine = (ConvertTo-DreamSkinProcessArgument -Value $Injector) + ' --watch --port 49333 --browser-id exit-fixture'
          }
        }
        function Stop-Process { throw 'A numeric-PID stop must never be called by this fixture.' }
        function Wait-Process { throw 'A numeric-PID wait must never be called by this fixture.' }
        $stopError = $null; $stopped = $null
        try { $stopped = Stop-DreamSkinRecordedInjector -State $state } catch { $stopError = $_ }
        if ($fixtureHandle.HandleReads -ne 1 -or $fixtureHandle.Refreshes -ne 1 -or $fixtureHandle.Disposes -ne 1) {
          throw "The native handle was not pinned, refreshed and disposed exactly once for $Mode."
        }
        switch ($Mode) {
          'identity-changed' {
            if ($null -eq $stopError -or $stopError.Exception.Message -notlike '*identity changed before shutdown*' -or
              $fixtureHandle.Kills -ne 0 -or $fixtureHandle.Waits -ne 0) {
              throw 'A changed identity after handle acquisition authorized a kill.'
            }
          }
          'wait-timeout' {
            if ($null -eq $stopError -or $stopError.Exception.Message -notlike '*injector did not stop*' -or
              $fixtureHandle.Kills -ne 1 -or $fixtureHandle.Waits -ne 1 -or $fixtureHandle.WaitMilliseconds -ne 15000) {
              throw 'An unconfirmed native exit did not fail within the 15000 ms wait contract.'
            }
          }
          'kill-failed' {
            if ($null -eq $stopError -or $stopError.Exception.Message -notlike '*Fixture kill failed*' -or
              $fixtureHandle.Kills -ne 1 -or $fixtureHandle.Waits -ne 0) {
              throw 'A failed kill of a live process was treated as successful.'
            }
          }
          'already-exited' {
            if ($null -ne $stopError -or $stopped -ne $true -or $fixtureHandle.Kills -ne 0 -or $fixtureHandle.Waits -ne 0) {
              throw 'An already-exited verified process was not harmless.'
            }
          }
        }
        Write-Output "PASS: native-handle $Mode contract."
      } $stopSource $mode $nodePath $injector
    }
  }
} finally {
  if ($null -ne $fixtureProcess) {
    if (-not $fixtureProcess.HasExited) { $fixtureProcess.Kill(); [void]$fixtureProcess.WaitForExit(5000) }
    $fixtureProcess.Dispose()
  }
  $resolved = [IO.Path]::GetFullPath($fixtureRoot)
  $temporaryPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
  if (-not $resolved.StartsWith($temporaryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing cleanup outside the temporary fixture root.'
  }
  Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
}
