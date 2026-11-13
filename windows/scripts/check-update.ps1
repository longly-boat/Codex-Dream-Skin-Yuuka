[CmdletBinding()]
param(
  [switch]$Json,
  [switch]$Interactive
)

$ErrorActionPreference = 'Stop'
$engineRoot = Split-Path -Parent $PSScriptRoot
$versionPath = Join-Path $engineRoot 'VERSION'
$repository = 'longly-boat/Codex-Dream-Skin-Yuuka'
$releasePage = "https://github.com/$repository/releases/latest"
. (Join-Path $PSScriptRoot 'localization-windows.ps1')
$stateRoot = Join-Path $env:LOCALAPPDATA 'CodexDreamSkinYuuka'
$language = Resolve-DreamSkinLanguage -StateRoot $stateRoot

function Get-DreamSkinUpdateText {
  param([Parameter(Mandatory = $true)][string]$Key, [object[]]$FormatArguments = @())
  Get-DreamSkinText -Key $Key -Language $language -FormatArguments $FormatArguments
}

function ConvertTo-DreamSkinVersion {
  param([Parameter(Mandatory = $true)][string]$Value)
  $normalized = $Value.Trim()
  if ($normalized.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
    $normalized = $normalized.Substring(1)
  }
  if ($normalized -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
    throw "Invalid release version: $Value"
  }
  $parsed = $null
  if (-not [version]::TryParse($normalized, [ref]$parsed)) {
    throw "Invalid release version: $Value"
  }
  return $parsed
}

function Show-DreamSkinUpdateResult {
  param([Parameter(Mandatory = $true)][object]$Result)
  Add-Type -AssemblyName System.Windows.Forms
  if ($Result.updateAvailable) {
    $choice = [System.Windows.Forms.MessageBox]::Show(
      ((Get-DreamSkinUpdateText -Key 'UpdateAvailable' -FormatArguments @($Result.latestVersion)) +
        [Environment]::NewLine + [Environment]::NewLine +
        (Get-DreamSkinUpdateText -Key 'UpdateQuestion')),
      (Get-DreamSkinUpdateText -Key 'UpdateTitle'),
      [System.Windows.Forms.MessageBoxButtons]::YesNo,
      [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
      Start-Process -FilePath $Result.releaseUrl | Out-Null
    }
    return
  }
  [void][System.Windows.Forms.MessageBox]::Show(
    $(if ($Result.noRelease) { Get-DreamSkinUpdateText -Key 'UpdateNoRelease' }
      else { Get-DreamSkinUpdateText -Key 'UpToDate' -FormatArguments @($Result.currentVersion) }),
    (Get-DreamSkinUpdateText -Key 'UpdateTitle'),
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
  )
}

try {
  if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) {
    throw "Installed version file is missing: $versionPath"
  }
  $currentText = ([System.IO.File]::ReadAllText($versionPath)).Trim()
  $current = ConvertTo-DreamSkinVersion -Value $currentText
  $headers = @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'CodexDreamSkinYuuka' }
  $noRelease = $false
  $previousProtocol = [Net.ServicePointManager]::SecurityProtocol
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repository/releases/latest" `
      -Headers $headers -Method Get -TimeoutSec 12
  } catch {
    # Windows PowerShell exposes HttpWebResponse; PowerShell 7 uses
    # HttpResponseMessage. Both carry the numeric HTTP StatusCode.
    $response = if ($_.Exception.PSObject.Properties['Response']) { $_.Exception.Response } else { $null }
    if ($null -ne $response -and [int]$response.StatusCode -eq 404) {
      $noRelease = $true
    } else { throw }
  } finally {
    [Net.ServicePointManager]::SecurityProtocol = $previousProtocol
  }
  $latest = $null
  if (-not $noRelease) {
    if (-not $release.tag_name) { throw 'GitHub did not return a release tag.' }
    $latest = ConvertTo-DreamSkinVersion -Value "$($release.tag_name)"
  }
  $result = [pscustomobject]@{
    currentVersion = "v$($current.ToString())"
    latestVersion = $(if ($noRelease) { $null } else { "v$($latest.ToString())" })
    updateAvailable = (-not $noRelease) -and ($latest -gt $current)
    noRelease = $noRelease
    releaseUrl = $releasePage
  }
  if ($Json) { $result | ConvertTo-Json -Compress }
  if ($Interactive) { Show-DreamSkinUpdateResult -Result $result }
  if (-not $Json -and -not $Interactive) {
    if ($noRelease) { Write-Host (Get-DreamSkinUpdateText -Key 'UpdateNoRelease') }
    else { Write-Host "$($result.currentVersion) -> $($result.latestVersion); update=$($result.updateAvailable)" }
  }
} catch {
  if ($Json) {
    [pscustomobject]@{ error = $_.Exception.Message; releaseUrl = $releasePage } | ConvertTo-Json -Compress
  }
  if ($Interactive) {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show(
      ((Get-DreamSkinUpdateText -Key 'UpdateFailed') + [Environment]::NewLine +
        [Environment]::NewLine + $_.Exception.Message),
      (Get-DreamSkinUpdateText -Key 'UpdateTitle'),
      [System.Windows.Forms.MessageBoxButtons]::OK,
      [System.Windows.Forms.MessageBoxIcon]::Warning
    )
  }
  if (-not $Json -and -not $Interactive) { throw }
  exit 1
}
