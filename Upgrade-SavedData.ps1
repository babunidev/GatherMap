[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ClientPath,
    [Parameter(Mandatory=$true)][string]$PreviousAddonName
)
$ErrorActionPreference = 'Stop'
if (Get-Process WoW -ErrorAction SilentlyContinue) { throw 'Fully close the game before migrating saved data.' }
if ($PreviousAddonName -notmatch '^[A-Za-z0-9_-]+$') { throw 'Use the previous add-on folder name only, without a path.' }
$newTocs = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.toc' -File)
if ($newTocs.Count -ne 1) { throw 'Keep this helper beside the new add-on TOC file.' }
$newName = $newTocs[0].BaseName
if ($PreviousAddonName -eq $newName) { throw 'The old and new add-on names must be different.' }
$client = (Resolve-Path -LiteralPath $ClientPath).Path
$oldToc = Join-Path $client "Interface\AddOns\$PreviousAddonName\$PreviousAddonName.toc"
if (-not (Test-Path -LiteralPath $oldToc)) { throw 'The previous add-on must still be installed so its saved-variable declarations can be read.' }
function Read-Variables([string]$Path) {
    $result = @{}
    foreach ($kind in @('SavedVariables', 'SavedVariablesPerCharacter')) {
        $match = [regex]::Match([IO.File]::ReadAllText($Path), "(?im)^##\s*${kind}:\s*([^\r\n]*)")
        $result[$kind] = @($match.Groups[1].Value -split '[,\s]+' | Where-Object { $_ })
        foreach ($name in $result[$kind]) { if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw 'Invalid saved-variable declaration.' } }
    }
    return $result
}
$oldVars = Read-Variables $oldToc
$newVars = Read-Variables $newTocs[0].FullName
$mapping = @{}
foreach ($kind in @('SavedVariables', 'SavedVariablesPerCharacter')) {
    if ($oldVars[$kind].Count -ne $newVars[$kind].Count) { throw 'The saved-variable layouts differ; no files changed.' }
    for ($i=0; $i -lt $oldVars[$kind].Count; $i++) { $mapping[$oldVars[$kind][$i]] = $newVars[$kind][$i] }
}
if ($mapping.Count -eq 0) { throw 'This add-on has no saved variables to migrate.' }
$account = Join-Path $client 'WTF\Account'
if (-not (Test-Path -LiteralPath $account)) { throw 'No WTF\Account folder was found.' }
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$jobs = @()
foreach ($source in Get-ChildItem -LiteralPath $account -Recurse -File -Filter "$PreviousAddonName.lua") {
    if ($source.Directory.Name -ne 'SavedVariables') { continue }
    $target = Join-Path $source.Directory.FullName "$newName.lua"
    if (Test-Path -LiteralPath $target) { throw "Saved data already exists at $target. Nothing was overwritten; merge or archive that file first." }
    $text = $utf8.GetString([IO.File]::ReadAllBytes($source.FullName)).TrimStart([char]0xFEFF)
    foreach ($old in $mapping.Keys) {
        $replacement = $mapping[$old]
        $text = [regex]::Replace($text, ('(?m)^(\s*)' + [regex]::Escape($old) + '(\s*=)'), ('${1}' + $replacement + '${2}'))
    }
    $jobs += [pscustomobject]@{ Source=$source.FullName; Target=$target; Text=$text }
}
if ($jobs.Count -eq 0) { Write-Output 'No previous saved-data files were found. No files changed.'; return }
$backup = Join-Path $client ('AddonUpgradeBackups\' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($backup) | Out-Null
foreach ($job in $jobs) {
    $relative = $job.Source.Substring($account.Length).TrimStart('\')
    $backupPath = Join-Path $backup $relative
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backupPath)) | Out-Null
    Copy-Item -LiteralPath $job.Source -Destination $backupPath
    if (Test-Path -LiteralPath ($job.Source + '.bak')) { Copy-Item -LiteralPath ($job.Source + '.bak') -Destination ($backupPath + '.bak') }
}
foreach ($job in $jobs) {
    # CreateNew also prevents overwriting a file created after preflight.
    $stream = [IO.File]::Open($job.Target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
    try { $bytes=$utf8.GetBytes($job.Text); $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
}
Write-Output "Copied $($jobs.Count) saved-data file(s). Original files remain intact. Backup: $backup"
Write-Output 'Before starting the game, disable the previous add-on and enable the new one.'
