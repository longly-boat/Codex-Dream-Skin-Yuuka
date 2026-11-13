[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'scripts\common-windows.ps1')
. (Join-Path $root 'scripts\theme-windows.ps1')
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('yuuka-product-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixture)
function Assert-Refused([scriptblock]$Action) {
  $refused = $false
  try { & $Action } catch { $refused = $true }
  if (-not $refused) { throw 'Expected unsafe coexistence to be refused.' }
}
try {
  $legacy = Join-Path $fixture 'legacy'
  $shortcut = Join-Path $fixture 'old-autolaunch.lnk'
  Assert-YuukaLegacyEngineInactive -LegacyRoot $legacy -LegacyStartupShortcut $shortcut
  [void][IO.Directory]::CreateDirectory($legacy)
  $backup = Join-Path $legacy 'config.before-dream-skin.toml'
  [IO.File]::WriteAllText($backup, 'original config sentinel')
  Assert-Refused { Assert-YuukaLegacyEngineInactive -LegacyRoot $legacy -LegacyStartupShortcut $shortcut }
  if ([IO.File]::ReadAllText($backup) -cne 'original config sentinel') { throw 'Legacy config was modified.' }
  Remove-Item -LiteralPath $backup
  [IO.File]::WriteAllText($shortcut, 'not a real shortcut; must never be removed')
  Assert-Refused { Assert-YuukaLegacyEngineInactive -LegacyRoot $legacy -LegacyStartupShortcut $shortcut }
  if (-not (Test-Path -LiteralPath $shortcut)) { throw 'Legacy startup entry was modified.' }

  $state = Join-Path $fixture 'yuuka'
  $paths = Initialize-DreamSkinThemeStore -SkillRoot $root -StateRoot $state
  $active = Read-DreamSkinTheme -ThemeDirectory $paths.Active
  if ($active.Theme.id -cne 'yuuka-seminar' -or $active.Theme.appearance -cne 'light') { throw 'Fresh install does not default to Yuuka light.' }
  $ids = @((Get-DreamSkinSavedThemes -StateRoot $state).Id | Sort-Object)
  if (($ids -join ',') -cne 'yuuka-seminar,yuuka-seminar-night') { throw 'Light/night presets missing.' }
  Assert-DreamSkinSafeCssFile -Path (Join-Path $paths.Active 'theme.css')
  $active.Theme.colors.panel = '#112233aa'
  Write-DreamSkinTheme -ThemeDirectory $paths.Active -Theme $active.Theme
  $before = (Get-FileHash -LiteralPath $active.ThemePath).Hash
  $null = Initialize-DreamSkinThemeStore -SkillRoot $root -StateRoot $state
  if ((Get-FileHash -LiteralPath $active.ThemePath).Hash -cne $before) { throw 'Reinitialization discarded customized opacity.' }
  $null = Use-DreamSkinSavedTheme -ThemeDirectory (Join-Path $paths.Saved 'yuuka-seminar-night') -StateRoot $state
  $null = Initialize-DreamSkinThemeStore -SkillRoot $root -StateRoot $state
  if ((Read-DreamSkinTheme -ThemeDirectory $paths.Active).Theme.id -cne 'yuuka-seminar-night') { throw 'Night selection was reset on launch.' }
  if ((Get-DreamSkinRuntimeEnginePaths).Root -notlike '*\CodexDreamSkinYuuka\engine') { throw 'Default runtime is not isolated.' }
  $quickfix = Read-DreamSkinUtf8File -Path (Join-Path $root 'installer\quickfix\fix.ps1')
  if (-not $quickfix.Contains("`$env:LOCALAPPDATA 'CodexDreamSkinYuuka'")) { throw 'Quick-fix packages target another product.' }
  Write-Host 'PASS: Yuuka defaults, light/night, opacity retention, identity and legacy coexistence guard.'
} finally {
  $full = [IO.Path]::GetFullPath($fixture)
  if (-not $full.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()), [StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($full) -notlike 'yuuka-product-*') { throw 'Unsafe fixture cleanup.' }
  Remove-Item -LiteralPath $full -Recurse -Force
}
