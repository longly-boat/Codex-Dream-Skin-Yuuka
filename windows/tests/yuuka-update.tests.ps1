param([string]$Root = (Join-Path $PSScriptRoot '..'))
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$updatePath = Join-Path $Root 'scripts/check-update.ps1'
$source = [IO.File]::ReadAllText($updatePath)
$tokens = $null; $parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($updatePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw $parseErrors }
# A separate PowerShell runspace permits testing the real script's exit 1
# without terminating the harness. No network or interactive UI is used.
$cases = @(
  @{ name='new'; status=200; tag='v99.0.0'; available=$true },
  @{ name='same'; status=200; tag=('v' + [IO.File]::ReadAllText((Join-Path $Root 'VERSION')).Trim()); available=$false },
  @{ name='older'; status=200; tag='v0.0.0'; available=$false },
  @{ name='missing'; status=404; noRelease=$true },
  @{ name='forbidden'; status=403; failure=$true },
  @{ name='server'; status=500; failure=$true },
  @{ name='transport'; status=0; failure=$true },
  @{ name='bad-version'; status=200; tag='v1.2.3;evil'; failure=$true },
  @{ name='missing-tag'; status=200; tag=''; failure=$true }
)
$runner = {
  param($Path, $Case)
  $global:caseData = $Case
  $global:calls = 0
  $global:originalProtocol = [Net.ServicePointManager]::SecurityProtocol
  function Invoke-RestMethod {
    param($Uri, $Headers, $Method, $TimeoutSec)
    $global:calls++
    if ($Uri -cne 'https://api.github.com/repos/longly-boat/Codex-Dream-Skin-Yuuka/releases/latest') { throw 'Untrusted update endpoint' }
    if ([Net.ServicePointManager]::SecurityProtocol -ne [Net.SecurityProtocolType]::Tls12) { throw 'TLS 1.2 missing' }
    if ($Method -ne 'Get' -or $TimeoutSec -ne 12) { throw 'Request guard changed' }
    if ($global:caseData.status -eq 0) { throw 'Simulated transport failure' }
    if ($global:caseData.status -ne 200) {
      $error = [Exception]::new('Simulated HTTP failure')
      $error | Add-Member -NotePropertyName Response -NotePropertyValue ([pscustomobject]@{StatusCode=$global:caseData.status})
      throw $error
    }
    return @{tag_name=$global:caseData.tag; html_url='https://untrusted.invalid/release'}
  }
  try { & $Path -Json }
  finally {
    if ($global:calls -ne 1) { throw 'Unexpected request count or upstream fallback' }
    if ([Net.ServicePointManager]::SecurityProtocol -ne $global:originalProtocol) { throw 'TLS configuration not restored' }
  }
}
foreach ($case in $cases) {
  $ps = [PowerShell]::Create()
  try {
    $output = @($ps.AddScript($runner.ToString()).AddArgument($updatePath).AddArgument($case).Invoke())
    if ($ps.Streams.Error.Count) { throw ($ps.Streams.Error | Out-String) }
    $result = ($output -join '') | ConvertFrom-Json
    if ($result.releaseUrl -cne 'https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/releases/latest') { throw 'Untrusted release URL' }
    if ($case.failure) {
      if (-not $result.error) { throw "Expected failure: $($case.name)" }
    } else {
      if ($result.error) { throw $result.error }
      if ($case.noRelease) {
        if (-not $result.noRelease -or $result.updateAvailable -or $null -ne $result.latestVersion) { throw 'Invalid no-release result' }
      } elseif ($result.noRelease -or $result.updateAvailable -ne $case.available) { throw "Version comparison failed: $($case.name)" }
    }
    Write-Output "PASS: $($case.name)"
  } finally { $ps.Dispose() }
}
. (Join-Path $Root 'scripts/localization-windows.ps1')
if ((Get-DreamSkinText -Key UpdateNoRelease -Language zh-CN) -cne '暂无发布版本') { throw 'Missing Chinese no-release text' }
if ($source -notmatch "'CodexDreamSkinYuuka'" -or $source -match 'EmiyaKatuz|Fei-Away') { throw 'Update identity is not isolated' }
$dialog = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Show-DreamSkinUpdateResult' }, $true)
if ($dialog.Extent.Text -notmatch '\$Result.noRelease' -or $dialog.Extent.Text -notmatch 'UpdateNoRelease') { throw 'Interactive no-release branch missing' }
Write-Output 'PASS: Chinese message, interactive branch and Yuuka identity'
