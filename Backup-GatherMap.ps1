[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ClientPath)
$ErrorActionPreference='Stop'
# This helper copies files, not Lua data structures. The game must be closed
# so its next SavedVariables flush cannot invalidate the external backup.
if (Get-Process WoW -ErrorAction SilentlyContinue) {
    throw 'Close World of Warcraft Forever before backing up SavedVariables.'
}
$client=(Resolve-Path -LiteralPath $ClientPath).Path
$account=Join-Path $client 'WTF\Account'
if (-not (Test-Path -LiteralPath $account -PathType Container)) {
    throw 'Could not find WTF\Account; nothing was changed.'
}
$paths=@()
foreach ($file in Get-ChildItem -LiteralPath $account -Recurse -File) {
    if ($file.Directory.Name -ne 'SavedVariables') { continue }
    if ($file.Name -in @('GatherMap.lua','GatherMap.lua.bak',
        'OctoGather.lua','OctoGather.lua.bak')) {
        $paths+= $file
    }
}
if ($paths.Count -eq 0) {
    Write-Output 'No GatherMap or OctoGather SavedVariables files were found.'
    return
}
$backup=Join-Path $client ('GatherMapBackups\' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($backup) | Out-Null
foreach ($file in $paths) {
    $relative=$file.FullName.Substring($account.Length).TrimStart('\','/')
    $target=Join-Path $backup $relative
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -ErrorAction Stop
}
Write-Output "Copied $($paths.Count) original SavedVariables file(s) without changing them."
Write-Output "Physical backup: $backup"
