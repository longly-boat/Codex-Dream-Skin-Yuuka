param([string]$Root = (Join-Path $PSScriptRoot '..'))
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
. (Join-Path $Root 'scripts/common-windows.ps1')
. (Join-Path $Root 'scripts/theme-windows.ps1')
$bootstrap = Join-Path $Root 'installer/setup-bootstrap.ps1'
$parseTokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($bootstrap, [ref]$parseTokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Bootstrap PowerShell syntax is invalid.' }
$functions = @('Get-YuukaAutoLaunchManager', 'Invoke-YuukaAutoLaunchControl', 'New-YuukaWatcherMaintenance', 'Suspend-YuukaWatcherMaintenance', 'Resume-YuukaWatcherMaintenance')
foreach ($name in $functions) {
  $definition = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name }, $true)
  if (-not $definition) { throw "Missing lifecycle function: $name" }
  . ([ScriptBlock]::Create($definition.Extent.Text))
}
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('yuuka-bootstrap-test-' + [Guid]::NewGuid().ToString('N'))
$stateRoot = Join-Path $testRoot 'CodexDreamSkinYuuka'
$manager = Join-Path $stateRoot 'engine/scripts/manage-auto-launch-dream-skin.ps1'
$utf8 = [Text.UTF8Encoding]::new($false)
$null = New-Item -ItemType Directory -Path $testRoot
function Check([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message }; Write-Output "PASS: $Message" }
function Refuses([scriptblock]$Action, [string]$Message) {
  $errorCaught = $false
  try { & $Action } catch { $errorCaught = $true }
  Check $errorCaught $Message
}
function Write-ControlFixture([string]$Generation = 'old') {
  $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($manager)) -Force
  # An isolated controller exercises the production PowerShell invocation,
  # JSON validation and flags, without starting/stopping any real watcher.
  $source = @'
param([switch]$Status, [switch]$Disable, [switch]$Enable, [switch]$ProtectCurrentSession)
$action = if ($Status) { 'Status' } elseif ($Disable) { 'Disable' } else { 'Enable' }
$global:YuukaBootstrapCalls.Add('__GENERATION__|' + $action + '|' + [bool]$ProtectCurrentSession)
if ($global:YuukaBootstrapFail -ceq $action) { throw 'Fixture control failure.' }
if ($global:YuukaBootstrapInvalidJson) { Write-Output '[{}]'; return }
if ($global:YuukaBootstrapInvalidStatus) { Write-Output '{"Enabled":"true"}'; return }
if ($Disable) { $global:YuukaBootstrapEnabled = $false; $global:YuukaBootstrapRunning = $false }
if ($Enable) { $global:YuukaBootstrapEnabled = $true; $global:YuukaBootstrapRunning = $true }
@{Enabled=$global:YuukaBootstrapEnabled; Running=$global:YuukaBootstrapRunning;
  ShortcutExists=$global:YuukaBootstrapEnabled; ShortcutManaged=$global:YuukaBootstrapEnabled;
  ShortcutError=$null; StateError=$null} | ConvertTo-Json -Compress
'@
  [IO.File]::WriteAllText($manager, $source.Replace('__GENERATION__', $Generation), $utf8)
}
try {
  $global:YuukaBootstrapCalls = [Collections.Generic.List[string]]::new()
  $global:YuukaBootstrapEnabled = $false
  $global:YuukaBootstrapRunning = $false
  $global:YuukaBootstrapFail = ''
  $global:YuukaBootstrapInvalidJson = $false
  $global:YuukaBootstrapInvalidStatus = $false
  Check ($null -eq (New-YuukaWatcherMaintenance -StateRoot $stateRoot)) 'fresh installation has no watcher to stop or enable'
  Check ($global:YuukaBootstrapCalls.Count -eq 0) 'fresh installation does not execute any controller'
  Write-ControlFixture
  Check ($null -eq (New-YuukaWatcherMaintenance -StateRoot $stateRoot)) 'disabled watcher remains disabled'
  $global:YuukaBootstrapEnabled = $true
  $global:YuukaBootstrapRunning = $true
  $maintenance = New-YuukaWatcherMaintenance -StateRoot $stateRoot
  Suspend-YuukaWatcherMaintenance -Maintenance $maintenance
  Check (-not $global:YuukaBootstrapEnabled -and -not $global:YuukaBootstrapRunning) 'maintenance stops the old watcher before engine replacement'
  Write-ControlFixture 'new'
  Resume-YuukaWatcherMaintenance -Maintenance $maintenance
  Check ($global:YuukaBootstrapEnabled -and $global:YuukaBootstrapRunning -and $global:YuukaBootstrapCalls.Contains('new|Enable|True')) 'successful replacement restores enabled state through the new engine and protects the open session'

  $maintenance = New-YuukaWatcherMaintenance -StateRoot $stateRoot
  Suspend-YuukaWatcherMaintenance -Maintenance $maintenance
  Write-ControlFixture 'rolled-back'
  Resume-YuukaWatcherMaintenance -Maintenance $maintenance
  Check ($global:YuukaBootstrapCalls.Contains('rolled-back|Enable|True')) 'failed replacement restores enabled state through the rolled-back engine'

  $global:YuukaBootstrapEnabled = $false
  $global:YuukaBootstrapRunning = $true
  $maintenance = New-YuukaWatcherMaintenance -StateRoot $stateRoot
  Suspend-YuukaWatcherMaintenance -Maintenance $maintenance
  $countBeforeResume = $global:YuukaBootstrapCalls.Count
  Resume-YuukaWatcherMaintenance -Maintenance $maintenance
  Check (-not $global:YuukaBootstrapEnabled -and $global:YuukaBootstrapCalls.Count -eq $countBeforeResume) 'a manually running watcher does not create a new startup preference'

  $global:YuukaBootstrapEnabled = $true
  $global:YuukaBootstrapRunning = $true
  $maintenance = New-YuukaWatcherMaintenance -StateRoot $stateRoot
  $global:YuukaBootstrapFail = 'Disable'
  Refuses { Suspend-YuukaWatcherMaintenance -Maintenance $maintenance } 'stop failure aborts maintenance'
  $global:YuukaBootstrapFail = 'Enable'
  Refuses { Resume-YuukaWatcherMaintenance -Maintenance $maintenance } 'restore failure remains an explicit error'
  $global:YuukaBootstrapFail = ''
  $global:YuukaBootstrapInvalidJson = $true
  Refuses { New-YuukaWatcherMaintenance -StateRoot $stateRoot } 'non-object controller status fails closed'
  $global:YuukaBootstrapInvalidJson = $false
  $global:YuukaBootstrapInvalidStatus = $true
  Refuses { New-YuukaWatcherMaintenance -StateRoot $stateRoot } 'invalid controller field types fail closed'
  $global:YuukaBootstrapInvalidStatus = $false

  Refuses { New-YuukaWatcherMaintenance -StateRoot (Join-Path $testRoot 'CodexDreamSkin') } 'upstream product root cannot enter Yuuka maintenance'
  $linkedRoot = Join-Path $testRoot 'redirected/CodexDreamSkinYuuka'
  $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($linkedRoot))
  $null = New-Item -ItemType Junction -Path $linkedRoot -Target $stateRoot
  try { Refuses { New-YuukaWatcherMaintenance -StateRoot $linkedRoot } 'redirected state root cannot execute a controller' }
  finally { [IO.Directory]::Delete($linkedRoot, $false) }

  $text = [IO.File]::ReadAllText($bootstrap)
  $maintenanceStart = $text.IndexOf('$watcherMaintenance = New-YuukaWatcherMaintenance')
  $installStart = $text.IndexOf("& (Join-Path `$payloadScripts 'install-dream-skin.ps1')")
  Check ($maintenanceStart -ge 0 -and $maintenanceStart -lt $installStart) 'installer suspends the watcher before invoking installation'
  Check ($text -match '(?s)finally\s*\{.*Resume-YuukaWatcherMaintenance' -and $text -match 'Yuuka automatic-launch recovery failed:') 'success and failure both restore previous settings and expose recovery failures'
} finally {
  foreach ($variable in @('YuukaBootstrapCalls','YuukaBootstrapEnabled','YuukaBootstrapRunning','YuukaBootstrapFail','YuukaBootstrapInvalidJson','YuukaBootstrapInvalidStatus')) {
    Remove-Variable -Name $variable -Scope Global -ErrorAction SilentlyContinue
  }
  $full = [IO.Path]::GetFullPath($testRoot)
  $prefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
  if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($full) -notlike 'yuuka-bootstrap-test-*') { throw 'Unsafe fixture cleanup path.' }
  Assert-DreamSkinNoReparseComponents -Path $full
  foreach ($entry in Get-ChildItem -LiteralPath $full -Recurse -Force) { Assert-DreamSkinNoReparseComponents -Path $entry.FullName }
  Remove-Item -LiteralPath $full -Recurse -Force
}
