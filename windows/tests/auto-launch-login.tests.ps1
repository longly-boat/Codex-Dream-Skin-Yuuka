param([string]$Root=(Join-Path $PSScriptRoot '..'))
$ErrorActionPreference='Stop'
$path=Join-Path $Root 'scripts\auto-launch-dream-skin.ps1'
$source=[IO.File]::ReadAllText($path)
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors}
foreach($name in @('New-DreamSkinAutoLaunchMachine','Copy-DreamSkinAutoLaunchMachine','Invoke-DreamSkinAutoLaunchTransition')){
 $definition=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
 . ([scriptblock]::Create($definition.Extent.Text))
}
$baseline=$ast.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$startupBaselineActive'},$true)
foreach($mode in @(@($false,$false,$true),@($true,$false,$false),@($true,$true,$true))){
 $TakeOverStartupSession=$mode[0];$ProtectCurrentSession=$mode[1]
 $baselineScanComplete=$false;$nowMilliseconds=0;$StartupBaselineMilliseconds=10000
 . ([scriptblock]::Create($baseline.Extent.Text))
 $state=New-DreamSkinAutoLaunchMachine -ProtectRequested $ProtectCurrentSession
 $first=Invoke-DreamSkinAutoLaunchTransition -State $state -ObservationSucceeded $true -ProcessCount 1 -StartupBaselineActive $startupBaselineActive -NowMilliseconds 0 -GraceMilliseconds 1000
 $second=Invoke-DreamSkinAutoLaunchTransition -State $first.State -ObservationSucceeded $true -ProcessCount 1 -StartupBaselineActive $startupBaselineActive -NowMilliseconds 1500 -GraceMilliseconds 1000
 if($mode[2]){if($second.Action -ne 'none' -or -not $second.State.ProtectionArmed){throw 'Existing-session protection lost'}}
 else {if($second.Action -ne 'restart'){throw 'Explicit login takeover failed to handle already-restored Codex'}}
}
Write-Output 'PASS: explicit login takeover handles restored sessions; default and explicit protection remain safe.'
