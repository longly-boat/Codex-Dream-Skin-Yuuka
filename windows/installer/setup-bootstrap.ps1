[CmdletBinding()]
param(
  [switch]$Install,
  [switch]$LaunchTray,
  [switch]$ShowWindow,
  [switch]$Uninstall,
  [switch]$Silent
)

$ErrorActionPreference = 'Stop'
$payloadRoot = Join-Path $PSScriptRoot 'payload'
$payloadScripts = Join-Path $payloadRoot 'scripts'
$commonPath = Join-Path $payloadScripts 'common-windows.ps1'
$themePath = Join-Path $payloadScripts 'theme-windows.ps1'
$stateRoot = Join-Path $env:LOCALAPPDATA 'CodexDreamSkinYuuka'
$startupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'Codex Dream Skin Yuuka.lnk'
$managerMaintenance = $null
$watcherMaintenance = $null
$bootstrapFailure = $null

function Get-YuukaAutoLaunchManager {
  param([Parameter(Mandatory = $true)][string]$StateRoot)
  $fullRoot = [IO.Path]::GetFullPath($StateRoot).TrimEnd('\')
  if ([IO.Path]::GetFileName($fullRoot) -ine 'CodexDreamSkinYuuka') {
    throw 'Watcher maintenance is limited to the independent Yuuka state directory.'
  }
  $enginePaths = Get-DreamSkinRuntimeEnginePaths -StateRoot $StateRoot
  Assert-DreamSkinNoReparseComponents -Path $enginePaths.Root
  if (-not (Test-Path -LiteralPath $enginePaths.Root)) { return $null }
  $manager = Join-Path $enginePaths.Scripts 'manage-auto-launch-dream-skin.ps1'
  Assert-DreamSkinNoReparseComponents -Path $manager
  if (-not (Test-Path -LiteralPath $manager -PathType Leaf)) {
    throw 'The installed Yuuka automatic-launch manager is missing; stop its watcher before repairing the runtime.'
  }
  return $manager
}

function Invoke-YuukaAutoLaunchControl {
  param(
    [Parameter(Mandatory = $true)][string]$ManagerPath,
    [Parameter(Mandatory = $true)][ValidateSet('Status', 'Disable', 'Enable')][string]$Action
  )
  Assert-DreamSkinNoReparseComponents -Path $ManagerPath
  if (-not (Test-Path -LiteralPath $ManagerPath -PathType Leaf)) { throw 'The Yuuka watcher control script is unavailable.' }
  $parameters = @{ $Action = $true }
  # Restoring a prior setting must never restart a session left open after a
  # cancelled/failed install. Future newly opened sessions remain eligible.
  if ($Action -ceq 'Enable') { $parameters.ProtectCurrentSession = $true }
  $json = (@(& $ManagerPath @parameters) -join "`n").Trim()
  if ($json.Length -gt 65536 -or -not $json.StartsWith('{')) { throw 'The Yuuka watcher returned an invalid status.' }
  $status = $json | ConvertFrom-Json -ErrorAction Stop
  foreach ($field in @('Enabled', 'Running', 'ShortcutExists', 'ShortcutManaged')) {
    if (-not $status.PSObject.Properties[$field] -or $status.$field -isnot [bool]) {
      throw 'The Yuuka watcher returned an incomplete status.'
    }
  }
  if ($status.ShortcutError -or $status.StateError -or
      ($status.ShortcutExists -and -not $status.ShortcutManaged)) {
    throw 'The existing Yuuka watcher state or startup entry could not be verified; no runtime replacement was attempted.'
  }
  return $status
}

function New-YuukaWatcherMaintenance {
  param([Parameter(Mandatory = $true)][string]$StateRoot)
  $manager = Get-YuukaAutoLaunchManager -StateRoot $StateRoot
  if (-not $manager) { return $null }
  $status = Invoke-YuukaAutoLaunchControl -ManagerPath $manager -Action Status
  if (-not $status.Enabled -and -not $status.Running) { return $null }
  return [pscustomobject]@{ StateRoot = $StateRoot; RestoreEnabled = $status.Enabled }
}

function Suspend-YuukaWatcherMaintenance {
  param([Parameter(Mandatory = $true)][object]$Maintenance)
  $manager = Get-YuukaAutoLaunchManager -StateRoot $Maintenance.StateRoot
  if (-not $manager) { throw 'The Yuuka runtime disappeared before stopping its watcher.' }
  $status = Invoke-YuukaAutoLaunchControl -ManagerPath $manager -Action Disable
  if ($status.Enabled -or $status.Running) { throw 'The Yuuka watcher did not stop; the runtime was not replaced.' }
}

function Resume-YuukaWatcherMaintenance {
  param([Parameter(Mandatory = $true)][object]$Maintenance)
  if (-not $Maintenance.RestoreEnabled) { return }
  # Resolve again after the atomic swap or rollback. Never execute a script
  # remembered inside a staging/backup tree or the upstream product's root.
  $manager = Get-YuukaAutoLaunchManager -StateRoot $Maintenance.StateRoot
  if (-not $manager) { throw 'The Yuuka runtime is missing; its previous automatic-launch setting could not be restored.' }
  $status = Invoke-YuukaAutoLaunchControl -ManagerPath $manager -Action Enable
  if (-not $status.Enabled -or -not $status.Running) { throw 'The prior Yuuka automatic-launch setting could not be restored.' }
}

function Show-DreamSkinBootstrapMessage {
  param(
    [Parameter(Mandatory = $true)][string]$Message,
    [ValidateSet('Info', 'Error')][string]$Kind = 'Info'
  )
  if ($Silent) { return }
  Add-Type -AssemblyName System.Windows.Forms
  $icon = if ($Kind -eq 'Error') {
    [System.Windows.Forms.MessageBoxIcon]::Error
  } else {
    [System.Windows.Forms.MessageBoxIcon]::Information
  }
  [void][System.Windows.Forms.MessageBox]::Show(
    $Message,
    'Codex Dream Skin Yuuka',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    $icon
  )
}

function Wait-DreamSkinCodexClosedForSetup {
  while ($true) {
    $registered = @(Get-DreamSkinRegisteredCodexInstalls)
    $running = @($registered | Where-Object { (Get-DreamSkinCodexProcesses -Codex $_).Count -gt 0 })
    if ($running.Count -eq 0) { return }
    if ($Silent) { throw 'Close Codex before installing or updating Codex Dream Skin Yuuka.' }
    Add-Type -AssemblyName System.Windows.Forms
    $choice = [System.Windows.Forms.MessageBox]::Show(
      'Codex is currently running. Close it, then click Retry to continue setup.',
      'Codex Dream Skin Yuuka Setup',
      [System.Windows.Forms.MessageBoxButtons]::RetryCancel,
      [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($choice -ne [System.Windows.Forms.DialogResult]::Retry) {
      throw 'Setup was cancelled because Codex is still running.'
    }
  }
}

try {
  if ($Install -and ($LaunchTray -or $Uninstall)) {
    throw 'Choose exactly one installer bootstrap action.'
  }
  if (-not (Test-Path -LiteralPath $commonPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $themePath -PathType Leaf)) {
    throw 'The installer payload is incomplete.'
  }
  . $commonPath
  . $themePath

  $engine = Get-DreamSkinRuntimeEnginePaths -StateRoot $stateRoot
  if ($Uninstall) {
    Stop-DreamSkinTrayProcess -ScriptPaths @($engine.Tray) -RequireStopped
    Stop-DreamSkinThemeManagerProcess -StateRoot $stateRoot
    $managerMaintenance = Enter-DreamSkinThemeManagerMaintenance
    $restoreRequired = (Test-Path -LiteralPath $engine.Root -PathType Container) -or
      (Test-Path -LiteralPath (Join-Path $stateRoot 'config.before-dream-skin.toml') -PathType Leaf)
    if ($restoreRequired -and -not (Test-Path -LiteralPath $engine.Restore -PathType Leaf)) {
      throw 'The installed restore engine is missing. Reinstall Codex Dream Skin Yuuka, then uninstall again so Codex can be restored safely.'
    }
    if ($restoreRequired) {
      $restoreParameters = @{
        Uninstall = $true
        ForceRestart = $true
        NoRelaunch = $true
      }
      if (Test-Path -LiteralPath (Join-Path $stateRoot 'config.before-dream-skin.toml') -PathType Leaf) {
        $restoreParameters.RestoreBaseTheme = $true
      }
      & $engine.Restore @restoreParameters
    }
    if (Test-Path -LiteralPath $engine.Root -PathType Container) {
      Remove-DreamSkinRuntimeTree -Path $engine.Root -StateRoot $stateRoot
    }
    Remove-Item -LiteralPath $startupShortcut -Force -ErrorAction SilentlyContinue
    exit 0
  }

  $payloadNode = Join-Path $payloadRoot 'runtime\node\node.exe'
  $payloadNodeLicense = Join-Path $payloadRoot 'runtime\node\LICENSE'
  if (-not (Test-Path -LiteralPath $payloadNode -PathType Leaf) -or
    -not (Test-Path -LiteralPath $payloadNodeLicense -PathType Leaf)) {
    throw 'The installer payload is missing its bundled Node.js runtime. Re-download Setup.exe.'
  }
  $payloadVersion = ([System.IO.File]::ReadAllText((Join-Path $payloadRoot 'VERSION'))).Trim()
  if ($payloadVersion -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
    throw "The installer payload version is invalid: $payloadVersion"
  }
  $installedVersion = if (Test-Path -LiteralPath $engine.Version -PathType Leaf) {
    ([System.IO.File]::ReadAllText($engine.Version)).Trim()
  } else { '' }
  if ($installedVersion -cmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -and
    ([version]$installedVersion) -gt ([version]$payloadVersion)) {
    throw "A newer Codex Dream Skin Yuuka v$installedVersion is already installed. Download that version or newer instead of downgrading to v$payloadVersion."
  }
  $backupExists = Test-Path -LiteralPath (Join-Path $stateRoot 'config.before-dream-skin.toml') -PathType Leaf
  $requiredEngineFiles = @(
    'VERSION',
    'assets\codex-dream-skin.ico',
    'assets\background.png',
    'assets\theme.css',
    'assets\yuuka-tray.ico',
    'assets\yuuka-tray.png',
    'assets\yuuka-renderer.js',
    'assets\yuuka-skin.css',
    'assets\yuuka-art.mjs',
    'presets\yuuka-seminar\theme.json',
    'presets\yuuka-seminar\theme.css',
    'presets\yuuka-seminar\background.png',
    'presets\yuuka-seminar-night\theme.json',
    'presets\yuuka-seminar-night\theme.css',
    'presets\yuuka-seminar-night\background.png',
    'assets\dream-skin.css',
    'assets\internet-angel-acrylic.css',
    'assets\internet-angel-extension.css',
    'assets\internet-angel-extension.js',
    'assets\renderer-inject.js',
    'assets\css-predicate-cache.mjs',
    'assets\theme-motion.js',
    'assets\theme-motion.css',
    'assets\motion-settings.mjs',
    'assets\motion-payload.mjs',
    'assets\safe-css-policy.json',
    'assets\safe-css-validator.mjs',
    'assets\selectors.json',
    'assets\theme-package-validator.mjs',
    'assets\theme-preferences.mjs',
    'assets\retired-theme-migration.mjs',
    'assets\retired-theme-catalog.json',
    'assets\theme.json',
    'scripts\apply-community-theme.ps1',
    'scripts\acrylic-window.ps1',
    'scripts\auto-launch-dream-skin.ps1',
    'scripts\auto-launch-hidden.cs',
    'scripts\check-update.ps1',
    'scripts\common-windows.ps1',
    'scripts\config-utf8.ps1',
    'scripts\image-metadata.mjs',
    'scripts\injector.mjs',
    'scripts\install-dream-skin.ps1',
    'scripts\yuuka-migration.ps1',
    'scripts\manage-auto-launch-dream-skin.ps1',
    'scripts\manage-window-effects.ps1',
    'scripts\patch-dream-skin.ps1',
    'scripts\localization-windows.ps1',
    'scripts\restore-dream-skin.ps1',
    'scripts\start-dream-skin.ps1',
    'scripts\theme-windows.ps1',
    'assets\theme-manager\DreamSkin.ThemeManager.exe',
    'scripts\tray-dream-skin.ps1',
    'scripts\validate-safe-css-file.mjs',
    'scripts\verify-dream-skin.ps1',
    'runtime\node\node.exe',
    'runtime\node\LICENSE'
  )
  $missingEngineFiles = @($requiredEngineFiles | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $engine.Root $_) -PathType Leaf)
  })
  $engineComplete = $missingEngineFiles.Count -eq 0
  $needsInstall = $Install -or $payloadVersion -cne $installedVersion -or
    -not $backupExists -or -not $engineComplete

  if ($needsInstall) {
    $watcherMaintenance = New-YuukaWatcherMaintenance -StateRoot $stateRoot
    if ($null -ne $watcherMaintenance) { Suspend-YuukaWatcherMaintenance -Maintenance $watcherMaintenance }
    Wait-DreamSkinCodexClosedForSetup
    Stop-DreamSkinTrayProcess -ScriptPaths @($engine.Tray) -RequireStopped
    # Close before install acquires Operation: FormClosing must be able to
    # acquire that lock itself to save a pending transparency adjustment.
    Stop-DreamSkinThemeManagerProcess -StateRoot $stateRoot
    & (Join-Path $payloadScripts 'install-dream-skin.ps1') -NoShortcuts
    $engine = Get-DreamSkinRuntimeEnginePaths -StateRoot $stateRoot
    $committedVersion = if (Test-Path -LiteralPath $engine.Version -PathType Leaf) {
      ([System.IO.File]::ReadAllText($engine.Version)).Trim()
    } else { '' }
    $missingEngineFiles = @($requiredEngineFiles | Where-Object {
      -not (Test-Path -LiteralPath (Join-Path $engine.Root $_) -PathType Leaf)
    })
    if ($committedVersion -cne $payloadVersion -or $missingEngineFiles.Count -gt 0 -or
      -not (Test-Path -LiteralPath (Join-Path $stateRoot 'config.before-dream-skin.toml') -PathType Leaf)) {
      throw 'Runtime installation did not commit a complete managed engine.'
    }
  }

  if ($LaunchTray) {
    $powershell = (Get-Command powershell.exe -ErrorAction Stop).Source
    $argumentLine = '-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File ' +
      (ConvertTo-DreamSkinProcessArgument -Value $engine.Tray)
    if ($ShowWindow) { $argumentLine += ' -ShowWindow' }
    Start-Process -FilePath $powershell -ArgumentList $argumentLine -WindowStyle Hidden | Out-Null
  }
} catch {
  $bootstrapFailure = $_.Exception.Message
} finally {
  if ($null -ne $managerMaintenance) {
    $managerMaintenance.ReleaseMutex()
    $managerMaintenance.Dispose()
  }
  if ($null -ne $watcherMaintenance) {
    try { Resume-YuukaWatcherMaintenance -Maintenance $watcherMaintenance } catch {
      $restoreFailure = 'Yuuka automatic-launch recovery failed: ' + $_.Exception.Message
      $bootstrapFailure = if ($bootstrapFailure) { $bootstrapFailure + "`r`n" + $restoreFailure } else { $restoreFailure }
    }
  }
}
if ($bootstrapFailure) {
  Show-DreamSkinBootstrapMessage -Message $bootstrapFailure -Kind Error
  Write-Error $bootstrapFailure -ErrorAction Continue
  exit 1
}
