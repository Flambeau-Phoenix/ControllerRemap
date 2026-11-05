param(
    [Parameter(Mandatory=$true)][string]$GamePath,
    [string]$ReleaseZip = ''
)
$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
if (!$ReleaseZip) {
    $modVersion = (Get-Content -LiteralPath (Join-Path $modRoot 'VERSION') -Raw).Trim()
    $ReleaseZip = Join-Path $modRoot "release/ControllerRemap-$modVersion.zip"
}
$gameRoot = (Resolve-Path -LiteralPath $GamePath).ProviderPath
if (!(Test-Path -LiteralPath (Join-Path $gameRoot 'Farever.exe') -PathType Leaf)) {
    throw 'Choose the actual game folder containing Farever.exe.'
}
$zipPath = (Resolve-Path -LiteralPath $ReleaseZip).ProviderPath
Add-Type -AssemblyName System.IO.Compression.FileSystem
$required = @(
    'hlx/mods/controllerremap/controllerremap.hl',
    'hlx/plugins/sfcursor/sfcursor.hdll',
    'hlx/plugins/sfimgui/sfimgui.hdll',
    'hlx/plugins/sfimgui/fonts/NotoSans-Regular.ttf'
)
$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
$results = @()
try {
    foreach ($relative in $required) {
        $entry = $archive.GetEntry($relative)
        if ($null -eq $entry) { throw "Reference ZIP is incomplete: $relative" }
        $entryStream = $entry.Open()
        $hash = [Security.Cryptography.SHA256]::Create()
        try { $wanted = [BitConverter]::ToString($hash.ComputeHash($entryStream)).Replace('-','').ToLowerInvariant() }
        finally { $entryStream.Dispose(); $hash.Dispose() }
        $deployed = Join-Path $gameRoot $relative
        $status = 'MISSING'
        if (Test-Path -LiteralPath $deployed -PathType Leaf) {
            $actual = (Get-FileHash -LiteralPath $deployed -Algorithm SHA256).Hash.ToLowerInvariant()
            $status = if ($actual -eq $wanted) { 'MATCH' } else { 'DIFFERENT' }
        }
        $results += [pscustomobject]@{ Status=$status; File=$relative }
    }
} finally { $archive.Dispose() }
$results | Format-Table -AutoSize
if (@($results | Where-Object { $_.Status -ne 'MATCH' }).Count) {
    throw 'Deployment differs from the release ZIP. MISSING means the file is absent at its required path; DIFFERENT means another version is deployed and needs review, not necessarily that it is incompatible. Resolve deployment/file conflicts and check again.'
}
Write-Output 'PASS all four deployed files match the release ZIP. Restart Farever to load them; this read-only check does not inspect loaded DLLs.'
