param([string]$HashLink = 'hl')
$ErrorActionPreference = 'Stop'
function Check([string]$Exe,[string[]]$Arguments,[string]$Expected='') {
    $output = & $Exe @Arguments 2>&1
    $result = $LASTEXITCODE
    $output | ForEach-Object { Write-Output $_ }
    $joined = $output -join "`n"
    if ($result -ne 0 -or $joined -match 'Uncaught exception|^FAIL:') { throw "$Exe failed" }
    if ($Expected -and !$joined.Contains($Expected)) { throw "Missing check result: $Expected" }
}
Push-Location $PSScriptRoot
try {
    $root = (Get-Location).Path
    New-Item -ItemType Directory -Path build -Force | Out-Null
    foreach ($suite in 'ProfileTest','ActionGroupsTest','ActionLabelsTest','BindingPlanTest','UiColorTest','SafeFileTest','OverrideSessionTest','WindowInputTest') {
        Check haxe @('-cp','src','-cp','tests','-main',$suite,'--interp') 'PASS '
    }
    Check haxe @('-cp','src','-cp','tests','-cp','tests/ui','-main','UiShellTest','--interp') 'PASS '
    foreach ($suite in 'EngineOverrideTest','ModeBindingsTest','ConflictBridgeTest') {
        $outputFile = Join-Path $root "build/$suite.hl"
        Check haxe @('-cp','src','-cp','tests','-cp','tests/engine','-main',$suite,'-hl',$outputFile)
        $work = Join-Path $root ('build/offline-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $work | Out-Null
        Push-Location $work
        try { Check $HashLink @($outputFile) 'PASS ' }
        finally { Pop-Location }
    }
    Write-Output 'PASS all offline ControllerRemap regression suites'
} finally { Pop-Location }
