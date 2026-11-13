function Import-YuukaLegacyPreferences {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$LegacyRoot,
    [Parameter(Mandatory = $true)][string]$StateRoot
  )
  # This is a one-time, copy-only migration. Call before initializing StateRoot.
  $ErrorActionPreference = 'Stop'
  $sourceRoot = [IO.Path]::GetFullPath($LegacyRoot).TrimEnd('\')
  $destinationRoot = [IO.Path]::GetFullPath($StateRoot).TrimEnd('\')
  foreach ($root in @($sourceRoot, $destinationRoot)) {
    if ($root -ieq [IO.Path]::GetPathRoot($root).TrimEnd('\')) { throw 'Migration cannot use a volume root.' }
  }
  function Assert-MigrationChild([string]$Root, [string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($Root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
      throw 'Yuuka migration path escaped its root.'
    }
    Assert-DreamSkinNoReparseComponents -Path $full
  }
  if ($sourceRoot -ieq $destinationRoot -or
      $sourceRoot.StartsWith($destinationRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or
      $destinationRoot.StartsWith($sourceRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Yuuka migration source and destination must be disjoint.'
  }
  # Never replace any existing destination, including a file or reparse point.
  if (Test-Path -LiteralPath $destinationRoot) { return $false }
  Assert-DreamSkinNoReparseComponents -Path $destinationRoot
  if (-not (Test-Path -LiteralPath $sourceRoot)) { return $false }
  Assert-DreamSkinNoReparseComponents -Path $sourceRoot
  if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) { throw 'Legacy root must be an ordinary directory.' }
  $parent = [IO.Path]::GetDirectoryName($destinationRoot)
  Assert-DreamSkinNoReparseComponents -Path $parent
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) { throw 'Yuuka state parent must already exist.' }
  $active = Join-Path $sourceRoot 'active-theme'
  if (-not (Test-Path -LiteralPath $active)) { return $false }
  $files = [Collections.Generic.List[object]]::new()
  function Get-MigrationFile([string]$Path, [long]$Limit, [switch]$AllowEmpty) {
    Assert-MigrationChild $sourceRoot $Path
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSIsContainer -or $item.Length -gt $Limit -or (-not $AllowEmpty -and $item.Length -eq 0)) {
      throw "Invalid or oversized Yuuka migration file: $Path"
    }
    return $item
  }
  function Read-MigrationObject([string]$Path) {
    $null = Get-MigrationFile $Path 65536
    $json = (Read-DreamSkinUtf8File -Path $Path).Trim()
    # PowerShell unwraps one-element JSON arrays in pipeline output, so check
    # the serialized root as well as the parsed value.
    if (-not $json.StartsWith('{')) { throw "Migration JSON must be an object: $Path" }
    $value = $json | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $value -or $value -isnot [pscustomobject]) { throw "Migration JSON must be an object: $Path" }
    return $value
  }
  function Add-MigrationFile([string]$Path, [string]$Relative, [long]$Limit, [switch]$AllowEmpty) {
    $item = Get-MigrationFile $Path $Limit -AllowEmpty:$AllowEmpty
    $files.Add([pscustomobject]@{
      Source=$item.FullName; Relative=$Relative; Bytes=$item.Length
      Hash=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
    })
  }
  $activeConfig = Read-MigrationObject (Join-Path $active 'theme.json')
  if (-not $activeConfig.PSObject.Properties['id'] -or
      $activeConfig.id -cnotin @('yuuka-seminar', 'yuuka-seminar-night')) { return $false }
  function Add-MigrationTheme([string]$Directory, [string]$Relative) {
    Assert-MigrationChild $sourceRoot $Directory
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { throw 'Theme must be an ordinary directory.' }
    # A flat three-file package is sufficient; unrelated ordinary files are
    # deliberately not copied. Nested directories/links are never traversed.
    foreach ($entry in Get-ChildItem -LiteralPath $Directory -Force) {
      Assert-MigrationChild $sourceRoot $entry.FullName
      if ($entry.PSIsContainer) { throw 'Nested theme directories are not supported by migration.' }
    }
    $metadata = Read-MigrationObject (Join-Path $Directory 'theme.json')
    if (-not $metadata.PSObject.Properties['image'] -or $metadata.image -isnot [string] -or
        $metadata.image -cnotmatch '^[^\\/:]+\.(png|jpe?g|webp)$' -or
        [IO.Path]::GetFileName($metadata.image) -cne $metadata.image) { throw 'Migration theme requires a flat image filename.' }
    $imagePath = Join-Path $Directory $metadata.image
    $null = Get-MigrationFile $imagePath 10MB
    $cssPath = Join-Path $Directory 'theme.css'
    $validated = Read-DreamSkinTheme -ThemeDirectory $Directory
    if ($Relative.StartsWith('themes\', [StringComparison]::OrdinalIgnoreCase) -and
        $validated.Theme.id -ceq 'preset-internet-angel-default' -and
        -not (Test-Path -LiteralPath $cssPath)) {
      Write-Verbose 'Leaving the legacy Internet Angel preset without Safe CSS in the source library.'
      return
    }
    $null = Get-MigrationFile $cssPath 256KB
    Assert-DreamSkinSafeCssFile -Path $cssPath
    Add-MigrationFile (Join-Path $Directory 'theme.json') (Join-Path $Relative 'theme.json') 64KB
    Add-MigrationFile $cssPath (Join-Path $Relative 'theme.css') 256KB
    Add-MigrationFile $imagePath (Join-Path $Relative $metadata.image) 10MB
  }
  Add-MigrationTheme $active 'active-theme'
  $saved = Join-Path $sourceRoot 'themes'
  if (Test-Path -LiteralPath $saved) {
    Assert-MigrationChild $sourceRoot $saved
    if (-not (Test-Path -LiteralPath $saved -PathType Container)) { throw 'Legacy themes path must be a directory.' }
    $entries = @(Get-ChildItem -LiteralPath $saved -Force)
    if ($entries.Count -gt 100) { throw 'Legacy theme library exceeds 100 entries.' }
    foreach ($entry in $entries) {
      Assert-MigrationChild $sourceRoot $entry.FullName
      if (-not $entry.PSIsContainer) { throw 'Unexpected file in legacy theme library.' }
      Add-MigrationTheme $entry.FullName (Join-Path 'themes' $entry.Name)
    }
  }
  foreach ($name in @('motion.json', 'theme-preferences.json', 'window-effects.json')) {
    $path = Join-Path $sourceRoot $name
    if (Test-Path -LiteralPath $path) {
      $settings = Read-MigrationObject $path
      $limit = 64KB
      if ($name -ceq 'window-effects.json') {
        $limit = 4096
        $null = Read-DreamSkinWindowEffects -StateRoot $sourceRoot
      } elseif ($name -ceq 'motion.json') {
        $limit = 16KB
        $null = Get-MigrationFile $path $limit
        $node = Get-DreamSkinNodeRuntime
        $helper = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\motion-settings.mjs'
        $validation = Invoke-DreamSkinNative -FilePath $node.Path -ArgumentList @($helper, '--get', '--file', $path)
        if ($validation.ExitCode -ne 0) { throw 'Legacy motion settings failed schema validation.' }
      } else {
        if (@($settings.PSObject.Properties.Name | Where-Object { $_ -cnotin @('schemaVersion', 'themes') }).Count -or
            -not $settings.PSObject.Properties['schemaVersion'] -or
            -not ($settings.schemaVersion -is [int] -or $settings.schemaVersion -is [long]) -or $settings.schemaVersion -ne 1 -or
            -not $settings.PSObject.Properties['themes'] -or $settings.themes -isnot [pscustomobject]) {
          throw 'Legacy theme preferences have an invalid schema.'
        }
        foreach ($themePreference in $settings.themes.PSObject.Properties) {
          $entry = $themePreference.Value
          if ($entry -isnot [pscustomobject] -or
              @($entry.PSObject.Properties.Name).Count -ne 1 -or -not $entry.PSObject.Properties['transparency']) {
            throw 'Legacy theme preferences must contain only transparency.'
          }
          $value = $entry.transparency
          if (-not ($value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal]) -or
              [double]::IsNaN([double]$value) -or [double]::IsInfinity([double]$value) -or $value -lt 0 -or $value -gt 100) {
            throw 'Legacy theme transparency must be a finite number from 0 to 100.'
          }
        }
      }
      Add-MigrationFile $path $name $limit
    }
  }
  $languagePath = Join-Path $sourceRoot 'language.txt'
  if (Test-Path -LiteralPath $languagePath) {
    $null = Get-MigrationFile $languagePath 16
    $language = (Read-DreamSkinUtf8File -Path $languagePath).Trim()
    if ($language -cnotin @('zh-CN', 'en-US')) { throw 'Invalid legacy language preference.' }
    Add-MigrationFile $languagePath 'language.txt' 16
  }
  $pausedPath = Join-Path $sourceRoot 'paused'
  if (Test-Path -LiteralPath $pausedPath) {
    $pausedFile = Get-MigrationFile $pausedPath 16 -AllowEmpty
    if ($pausedFile.Length -gt 0 -and (Read-DreamSkinUtf8File -Path $pausedPath).Trim() -cne 'paused') {
      throw 'Invalid legacy pause marker.'
    }
    Add-MigrationFile $pausedPath 'paused' 16 -AllowEmpty
  }
  $stage = Join-Path $parent ('.yuuka-migration-' + [Guid]::NewGuid().ToString('N'))
  Assert-MigrationChild $parent $stage
  if (Test-Path -LiteralPath $stage) { throw 'Migration staging path already exists.' }
  $stageOwned = $false
  try {
    $null = New-Item -ItemType Directory -Path $stage -ErrorAction Stop
    $stageOwned = $true
    foreach ($file in $files) {
      $target = Join-Path $stage $file.Relative
      Assert-MigrationChild $stage $target
      $targetParent = [IO.Path]::GetDirectoryName($target)
      if (-not (Test-Path -LiteralPath $targetParent)) { $null = New-Item -ItemType Directory -Path $targetParent -Force }
      Assert-MigrationChild $stage $target
      Assert-MigrationChild $sourceRoot $file.Source
      [IO.File]::Copy($file.Source, $target, $false)
    }
    foreach ($file in $files) {
      $target = Join-Path $stage $file.Relative
      Assert-MigrationChild $stage $target
      Assert-MigrationChild $sourceRoot $file.Source
      foreach ($path in @($file.Source, $target)) {
        if ((Get-Item -LiteralPath $path -Force).Length -ne $file.Bytes -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $file.Hash) {
          throw 'Migration source changed or copied file failed SHA-256 verification.'
        }
      }
    }
    Assert-MigrationChild $parent $stage
    Assert-DreamSkinNoReparseComponents -Path $destinationRoot
    if (Test-Path -LiteralPath $destinationRoot) { throw 'Yuuka state appeared during migration; refusing to overwrite.' }
    [IO.Directory]::Move($stage, $destinationRoot)
    $stageOwned = $false
    return $true
  } finally {
    if ($stageOwned -and (Test-Path -LiteralPath $stage)) {
      # Never recursively delete an unverified path. Delete only this bounded,
      # freshly-created staging tree after checking every component for links.
      Assert-MigrationChild $parent $stage
      $leftovers = [Collections.Generic.List[object]]::new()
      $pending = [Collections.Generic.Queue[string]]::new()
      $pending.Enqueue($stage)
      while ($pending.Count) {
        $directory = $pending.Dequeue()
        Assert-DreamSkinNoReparseComponents -Path $directory
        foreach ($entry in Get-ChildItem -LiteralPath $directory -Force) {
          Assert-MigrationChild $stage $entry.FullName
          $leftovers.Add($entry)
          if ($leftovers.Count -gt 1000) { throw 'Unexpected staging contents; retained for inspection.' }
          if ($entry.PSIsContainer) { $pending.Enqueue($entry.FullName) }
        }
      }
      foreach ($entry in $leftovers | Where-Object { -not $_.PSIsContainer }) { [IO.File]::Delete($entry.FullName) }
      foreach ($entry in $leftovers | Where-Object { $_.PSIsContainer } | Sort-Object { $_.FullName.Length } -Descending) { [IO.Directory]::Delete($entry.FullName, $false) }
      [IO.Directory]::Delete($stage, $false)
    }
  }
}
