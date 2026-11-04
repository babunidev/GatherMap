$ErrorActionPreference = 'Stop'
$addonRoot = Split-Path -Parent $PSScriptRoot
$newName = Split-Path -Leaf $addonRoot
$tocPath = Join-Path $addonRoot ($newName + '_Camelot.toc')
if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
    $tocPath = Join-Path $addonRoot ($newName + '.toc')
}
$toc = Get-Item -LiteralPath $tocPath
if (@(Get-ChildItem -LiteralPath $addonRoot -Filter '*.toc' -File).Count -lt 2) {
    throw 'Fixture must exercise the Forever directory with multiple manifests.'
}
$declaration = [regex]::Match([IO.File]::ReadAllText($toc.FullName), '(?m)^## (SavedVariables(?:PerCharacter)?): (\w+)')
if (-not $declaration.Success) { throw 'Missing saved-variable declaration.' }
$newVariable = $declaration.Groups[2].Value
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('addon-migration-test-' + [guid]::NewGuid().ToString('N'))
$oldRoot = Join-Path $testRoot 'Interface\AddOns\PreviousExample'
[IO.Directory]::CreateDirectory($oldRoot) | Out-Null
[IO.File]::WriteAllText((Join-Path $oldRoot 'PreviousExample.toc'), ('## ' + $declaration.Groups[1].Value + ': PreviousDB'))
$locations = @('WTF\Account\TestAccount\SavedVariables', 'WTF\Account\TestAccount\TestRealm\TestCharacter\SavedVariables')
$original = @'
PreviousDB = {
    ["label"] = "PreviousDB = keep this string; åäö",
    ["count"] = 27,
}
'@
# Test only temporary fixtures, independent of a running game.
function Get-Process { param($Name,$ErrorAction) return $null }
foreach ($relative in $locations) {
    $directory=Join-Path $testRoot $relative
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    [IO.File]::WriteAllText((Join-Path $directory 'PreviousExample.lua'),$original)
}
& (Join-Path $addonRoot 'Upgrade-SavedData.ps1') -ClientPath $testRoot -PreviousAddonName PreviousExample
foreach ($relative in $locations) {
    $directory=Join-Path $testRoot $relative
    if ([IO.File]::ReadAllText((Join-Path $directory 'PreviousExample.lua')) -cne $original) { throw 'Original data changed.' }
    $expected=$original.Replace('PreviousDB = {', "$newVariable = {")
    if ([IO.File]::ReadAllText((Join-Path $directory "$newName.lua")) -cne $expected) { throw 'Migrated data differs from expected table.' }
}
$backups=@(Get-ChildItem -LiteralPath (Join-Path $testRoot 'AddonUpgradeBackups') -Filter '*.lua' -Recurse -File)
if ($backups.Count -ne 2) { throw 'Missing backups.' }
$refused=$false
try { & (Join-Path $addonRoot 'Upgrade-SavedData.ps1') -ClientPath $testRoot -PreviousAddonName PreviousExample } catch { $refused=$_.Exception.Message -like '*already exists*' }
if (-not $refused) { throw 'Existing destination was not protected.' }
$refused=$false
try { & (Join-Path $addonRoot 'Upgrade-SavedData.ps1') -ClientPath $testRoot -PreviousAddonName '..\escape' } catch { $refused=$true }
if (-not $refused) { throw 'Invalid folder name was accepted.' }
# Back up active GatherMap and historical OctoGather variables separately;
# verify no originals are modified and rerunning creates new backup directories.
$extraDir = Join-Path $testRoot $locations[0]
[IO.File]::WriteAllText((Join-Path $extraDir 'OctoGather.lua'), 'OctoGatherDB = { ["count"]=12 }')
[IO.File]::WriteAllText((Join-Path $extraDir 'GatherMap.lua.bak'), 'GatherMapDB = { ["old"]=true }')
& (Join-Path $addonRoot 'Backup-GatherMap.ps1') -ClientPath $testRoot
$backupSets = @(Get-ChildItem -LiteralPath (Join-Path $testRoot 'GatherMapBackups') -Directory)
if ($backupSets.Count -ne 1) { throw 'Expected one physical backup directory.' }
$backedUp = @(Get-ChildItem -LiteralPath $backupSets[0].FullName -Recurse -File)
if ($backedUp.Count -ne 4) { throw "Expected four source files in physical backup, found $($backedUp.Count)." }
foreach ($file in $backedUp) {
    $relative=$file.FullName.Substring($backupSets[0].FullName.Length).TrimStart('\','/')
    $source=Join-Path (Join-Path $testRoot 'WTF\Account') $relative
    if (-not (Test-Path -LiteralPath $source)) { throw "Backup source missing: $relative" }
    if ([IO.File]::ReadAllBytes($source).Length -ne [IO.File]::ReadAllBytes($file.FullName).Length) {
        throw "Backup changed file size: $relative"
    }
}
& (Join-Path $addonRoot 'Backup-GatherMap.ps1') -ClientPath $testRoot
$backupSets = @(Get-ChildItem -LiteralPath (Join-Path $testRoot 'GatherMapBackups') -Directory)
if ($backupSets.Count -ne 2) { throw 'Repeated physical backups must not overwrite.' }
Write-Output "PASS: Forever multi-TOC rename, Unicode, original preservation, physical backups and no overwrite."
