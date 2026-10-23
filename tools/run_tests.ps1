# Runs the Godot headless suite, then the Python validator self-test.
# Refuses the Godot 4.0 install. GODOT_BIN overrides the path in PROJECT_STATUS.md.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root

function Get-GodotBin {
    if ($env:GODOT_BIN -and $env:GODOT_BIN.Trim() -ne "") {
        return $env:GODOT_BIN.Trim()
    }
    $status = Get-Content -LiteralPath (Join-Path $Root "PROJECT_STATUS.md") -Raw
    $match = [regex]::Match($status, "PINNED ``([^``]+)``")
    if (-not $match.Success) {
        throw "GODOT_BIN is unset and PROJECT_STATUS.md has no pinned Godot path."
    }
    return $match.Groups[1].Value
}

$Godot = Get-GodotBin
if ($Godot -like "*Godot_v4.0*") {
    Write-Error "Refusing Godot 4.0 at $Godot. Use the pinned 4.7.2 console executable."
    exit 2
}
if (-not (Test-Path -LiteralPath $Godot)) {
    Write-Error "Godot executable not found: $Godot"
    exit 2
}

Write-Host "GODOT_BIN=$Godot"
& $Godot --headless --path $Root --import
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$godotArgs = @("--headless", "--path", $Root, "--script", "res://tests/run_all.gd")
if ($args.Count -gt 0) {
    $godotArgs += "--"
    $godotArgs += $args
}
& $Godot @godotArgs
$godotCode = $LASTEXITCODE
if ($godotCode -ne 0) { exit $godotCode }

python -m unittest discover -s tools/validate -p "test_*.py"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python -m unittest discover -s tools/status -p "test_*.py"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
gdlint src tests
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
gdformat --check src tests
exit $LASTEXITCODE
