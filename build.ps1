$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    New-Item -ItemType Directory -Path build -Force | Out-Null
    & haxe compile.hxml
    if ($LASTEXITCODE -ne 0) { throw 'Haxe build failed.' }
    Write-Output 'Built build/controllerremap.hl'
} finally { Pop-Location }
