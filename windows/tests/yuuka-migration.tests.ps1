param([string]$Root = (Join-Path $PSScriptRoot '..'))
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
. (Join-Path $Root 'scripts/common-windows.ps1')
. (Join-Path $Root 'scripts/theme-windows.ps1')
. (Join-Path $Root 'scripts/yuuka-migration.ps1')
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('yuuka-migration-test-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $testRoot
$utf8 = [Text.UTF8Encoding]::new($false)
function New-Pack([string]$Path, [string]$Id = 'yuuka-seminar') {
  $null = New-Item -ItemType Directory -Path $Path -Force
  [IO.File]::WriteAllText((Join-Path $Path 'theme.json'), (@{schemaVersion=1;id=$Id;name='Migration fixture';image='background.jpg';appearance='auto'} | ConvertTo-Json), $utf8)
  [IO.File]::WriteAllText((Join-Path $Path 'theme.css'), '[data-ds-part="home-hero"] { color: #123456; }', $utf8)
  Copy-Item -LiteralPath (Join-Path $Root 'assets/dream-reference.jpg') -Destination (Join-Path $Path 'background.jpg')
}
function New-Case([string]$Name, [string]$Id = 'yuuka-seminar') {
  $dir = Join-Path $testRoot $Name
  $null = New-Item -ItemType Directory -Path $dir
  $legacy = Join-Path $dir 'legacy'
  New-Pack (Join-Path $legacy 'active-theme') $Id
  return @{LegacyRoot=$legacy; StateRoot=(Join-Path $dir 'yuuka')}
}
function Get-TreeFingerprint([string]$Path) {
  return (@(Get-ChildItem -LiteralPath $Path -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
    $_.FullName.Substring($Path.Length) + '|' + $_.Length + '|' + (Microsoft.PowerShell.Utility\Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
  }) -join "`n")
}
function Assert-Rejected($Case) {
  $failure = $null
  try { $null = Import-YuukaLegacyPreferences @Case } catch { $failure = $_ }
  if (-not $failure) { throw 'Expected migration rejection.' }
  if (Test-Path -LiteralPath $Case.StateRoot) { throw 'Rejected migration polluted destination.' }
  if (@(Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($Case.StateRoot)) -Force | Where-Object Name -Like '.yuuka-migration-*').Count) { throw 'Rejected migration leaked staging.' }
}
try {
  $case = New-Case 'success'
  New-Pack (Join-Path $case.LegacyRoot 'themes/other') 'other-theme'
  [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'motion.json'), '{"schemaVersion":1,"mode":"subtle","effects":{"interactions":true,"status":true,"character":false,"ambient":true,"themeTransition":true}}', $utf8)
  [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'theme-preferences.json'), '{"schemaVersion":1,"themes":{"yuuka-seminar":{"transparency":37.5}}}', $utf8)
  $null = Write-DreamSkinWindowEffects -WindowMaterial acrylic -StateRoot $case.LegacyRoot
  [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'language.txt'), 'zh-CN', $utf8)
  [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'paused'), '', $utf8)
  foreach ($name in @('state.json','auth.json','injector.log','config.toml')) { [IO.File]::WriteAllText((Join-Path $case.LegacyRoot $name), 'DO NOT COPY', $utf8) }
  $null = New-Item -ItemType Directory -Path (Join-Path $case.LegacyRoot 'engine')
  $before = Get-TreeFingerprint $case.LegacyRoot
  if (-not (Import-YuukaLegacyPreferences @case)) { throw 'Expected migration.' }
  if ((Get-TreeFingerprint $case.LegacyRoot) -cne $before) { throw 'Source changed.' }
  foreach ($name in @('state.json','auth.json','injector.log','config.toml','engine')) {
    if (Test-Path -LiteralPath (Join-Path $case.StateRoot $name)) { throw "Forbidden copied file: $name" }
  }
  $actual = @(Get-ChildItem -LiteralPath $case.StateRoot -File -Recurse)
  if ($actual.Count -ne 11) { throw "Whitelist files missing: $($actual.Count)" }
  foreach ($file in $actual) {
    $relative = $file.FullName.Substring($case.StateRoot.Length + 1)
    if ((Get-FileHash -LiteralPath $file.FullName).Hash -cne (Get-FileHash -LiteralPath (Join-Path $case.LegacyRoot $relative)).Hash) { throw 'Copied content differs.' }
  }
  $destinationBefore = Get-TreeFingerprint $case.StateRoot
  if (Import-YuukaLegacyPreferences @case) { throw 'Existing state must not migrate.' }
  if ((Get-TreeFingerprint $case.StateRoot) -cne $destinationBefore) { throw 'Existing state overwritten.' }
  Write-Output 'PASS: whitelist, source/copy hashes, non-Yuuka saved theme, existing destination preserved'

  $case = New-Case 'legacy-library'
  foreach ($id in @('yuuka-seminar', 'yuuka-seminar-night')) {
    $pack = Join-Path $case.LegacyRoot ('themes/' + $id)
    $null = New-Item -ItemType Directory -Path $pack -Force
    foreach ($file in @('theme.json', 'theme.css', 'background.png')) {
      Copy-Item -LiteralPath (Join-Path $Root ('presets/' + $id + '/' + $file)) -Destination (Join-Path $pack $file)
    }
  }
  $oldPack = Join-Path $case.LegacyRoot 'themes/preset-internet-angel-default'
  New-Pack $oldPack 'preset-internet-angel-default'
  [IO.File]::Delete((Join-Path $oldPack 'theme.css'))
  $null = Set-DreamSkinPaused -Paused $true -StateRoot $case.LegacyRoot
  $before = Get-TreeFingerprint $case.LegacyRoot
  if (-not (Import-YuukaLegacyPreferences @case)) { throw 'Legacy library did not migrate.' }
  if ((Get-TreeFingerprint $case.LegacyRoot) -cne $before -or
      (Test-Path -LiteralPath (Join-Path $case.StateRoot 'themes/preset-internet-angel-default')) -or
      @(Get-ChildItem -LiteralPath (Join-Path $case.StateRoot 'themes') -Directory).Count -ne 2) {
    throw 'Legacy preset was copied or source/preset library was changed.'
  }
  if (-not (Test-DreamSkinPaused -StateRoot $case.StateRoot) -or
      (Get-FileHash -LiteralPath (Join-Path $case.StateRoot 'paused')).Hash -cne
      (Get-FileHash -LiteralPath (Join-Path $case.LegacyRoot 'paused')).Hash) { throw 'Native pause marker was not preserved.' }
  Write-Output 'PASS: two Yuuka presets migrated; CSS-less legacy default remains only in source'
  Write-Output 'PASS: native Set-DreamSkinPaused marker retained byte-for-byte'

  foreach ($variant in @('custom', 'bad-image', 'linked-image')) {
    $case = New-Case ('css-less-' + $variant)
    $pack = Join-Path $case.LegacyRoot 'themes/old'
    $id = if ($variant -eq 'custom') { 'user-custom' } else { 'preset-internet-angel-default' }
    New-Pack $pack $id
    [IO.File]::Delete((Join-Path $pack 'theme.css'))
    $link = $null
    if ($variant -eq 'bad-image') { [IO.File]::WriteAllText((Join-Path $pack 'background.jpg'), 'invalid image', $utf8) }
    if ($variant -eq 'linked-image') {
      # A linked theme directory must be rejected before considering the skip.
      $link = Join-Path $case.LegacyRoot 'themes/linked-old'
      $null = New-Item -ItemType Junction -Path $link -Target $pack
    }
    try { Assert-Rejected $case } finally { if ($link) { [IO.Directory]::Delete($link, $false) } }
    Write-Output "PASS: CSS-less $variant is not an unsafe migration bypass"
  }

  $case = New-Case 'not-yuuka' 'preset-internet-angel-default'
  if (Import-YuukaLegacyPreferences @case) { throw 'Non-Yuuka active theme imported.' }
  if (Test-Path -LiteralPath $case.StateRoot) { throw 'Non-Yuuka state created.' }
  if (Import-YuukaLegacyPreferences -LegacyRoot (Join-Path $testRoot 'missing') -StateRoot (Join-Path $testRoot 'unused')) { throw 'Missing source imported.' }
  Write-Output 'PASS: non-Yuuka and missing source skipped'

  foreach ($bad in @('bad-json','array-json','empty-css','unsafe-css','bad-language','nonempty-paused','oversized-json')) {
    $case = New-Case $bad
    switch ($bad) {
      'bad-json' { [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'motion.json'), '{broken', $utf8) }
      'array-json' { [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'motion.json'), '[{}]', $utf8) }
      'empty-css' { [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'active-theme/theme.css'), '', $utf8) }
      'unsafe-css' { [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'active-theme/theme.css'), 'body { display: none; }', $utf8) }
      'bad-language' { [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'language.txt'), 'fr-FR', $utf8) }
      'nonempty-paused' { [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'paused'), 'bad', $utf8) }
      'oversized-json' { [IO.File]::WriteAllText((Join-Path $case.LegacyRoot 'motion.json'), (' ' * 65537), $utf8) }
    }
    $before = Get-TreeFingerprint $case.LegacyRoot
    Assert-Rejected $case
    if ((Get-TreeFingerprint $case.LegacyRoot) -cne $before) { throw 'Rejected migration changed source.' }
    Write-Output "PASS: $bad rejected without target pollution"
  }
  $invalidSettings = @(
    @{name='window-effects.json'; json='{"fixture":true}'},
    @{name='window-effects.json'; json='{"schemaVersion":1,"platform":"windows","windowMaterial":"bad"}'},
    @{name='motion.json'; json='{"fixture":true}'},
    @{name='motion.json'; json='{"schemaVersion":1,"mode":"off","effects":{"interactions":"false","status":true,"character":true,"ambient":true,"themeTransition":true}}'},
    @{name='theme-preferences.json'; json='{"schemaVersion":2,"themes":{}}'},
    @{name='theme-preferences.json'; json='{"schemaVersion":1,"themes":[]}'},
    @{name='theme-preferences.json'; json='{"schemaVersion":1,"themes":{"yuuka-seminar":{"transparency":"50"}}}'},
    @{name='theme-preferences.json'; json='{"schemaVersion":1,"themes":{"yuuka-seminar":{"transparency":101}}}'},
    @{name='theme-preferences.json'; json='{"schemaVersion":1,"themes":{"yuuka-seminar":{"transparency":-1}}}'},
    @{name='theme-preferences.json'; json='{"schemaVersion":1,"themes":{"yuuka-seminar":{"transparency":20,"unknown":true}}}'}
  )
  $index = 0
  foreach ($invalid in $invalidSettings) {
    $case = New-Case ('schema-' + $index++)
    [IO.File]::WriteAllText((Join-Path $case.LegacyRoot $invalid.name), $invalid.json, $utf8)
    $before = Get-TreeFingerprint $case.LegacyRoot
    Assert-Rejected $case
    if ((Get-TreeFingerprint $case.LegacyRoot) -cne $before) { throw 'Schema failure changed source.' }
    Write-Output "PASS: invalid $($invalid.name) schema $index rejected before destination creation"
  }
  $case = New-Case 'corrupt-copy'
  $before = Get-TreeFingerprint $case.LegacyRoot
  function Get-FileHash {
    param($LiteralPath, $Algorithm='SHA256')
    $hash = Microsoft.PowerShell.Utility\Get-FileHash -LiteralPath $LiteralPath -Algorithm $Algorithm
    if ($LiteralPath -like '*\.yuuka-migration-*\*') { $hash.Hash = 'CORRUPT' }
    return $hash
  }
  try { Assert-Rejected $case } finally { Remove-Item Function:\Get-FileHash }
  if ((Get-TreeFingerprint $case.LegacyRoot) -cne $before) { throw 'Failed copy changed source.' }
  Write-Output 'PASS: staged hash mismatch rolls back only owned staging'

  $case = New-Case 'reparse'
  $link = Join-Path $case.LegacyRoot 'active-theme/linked-directory'
  $null = New-Item -ItemType Junction -Path $link -Target (Join-Path $testRoot 'success')
  try { Assert-Rejected $case } finally { [IO.Directory]::Delete($link, $false) }
  Write-Output 'PASS: nested reparse rejected'
  $case = New-Case 'contained'
  Assert-Rejected @{LegacyRoot=$case.LegacyRoot; StateRoot=(Join-Path $case.LegacyRoot 'nested')}
  Write-Output 'PASS: overlapping roots rejected'
} finally {
  # Fixture root is a fresh, bounded temp directory. All created junctions
  # have been removed non-recursively before this cleanup.
  $fullTestRoot = [IO.Path]::GetFullPath($testRoot)
  $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
  if (-not $fullTestRoot.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase) -or
      [IO.Path]::GetFileName($fullTestRoot) -notlike 'yuuka-migration-test-*') { throw 'Unsafe fixture cleanup path.' }
  Assert-DreamSkinNoReparseComponents -Path $fullTestRoot
  foreach ($entry in Get-ChildItem -LiteralPath $fullTestRoot -Force -Recurse) { Assert-DreamSkinNoReparseComponents -Path $entry.FullName }
  Remove-Item -LiteralPath $fullTestRoot -Recurse -Force
}
