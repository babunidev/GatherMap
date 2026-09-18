$ErrorActionPreference = 'Stop'
$addonRoot = Split-Path -Parent $PSScriptRoot
$toc = Get-ChildItem -LiteralPath $addonRoot -Filter '*.toc' -File | Select-Object -First 1
$newName = $toc.BaseName
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
Write-Output "PASS: $newName migration preserves tables, Unicode, original files and backups; refuses overwrite and path traversal."
