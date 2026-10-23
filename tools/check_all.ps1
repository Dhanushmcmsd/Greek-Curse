# One-screen check: tests, data validation, and the status checker when it exists.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root

& powershell -NoProfile -File (Join-Path $PSScriptRoot "run_tests.ps1") @args
if ($LASTEXITCODE -ne 0) {
    Write-Host "check_all: FAIL (tests)"
    exit $LASTEXITCODE
}

python (Join-Path $Root "tools\validate\validate_all.py")
if ($LASTEXITCODE -ne 0) {
    Write-Host "check_all: FAIL (validate_all)"
    exit $LASTEXITCODE
}

$Godot = $env:GODOT_BIN
if (-not $Godot) {
    $status = Get-Content -LiteralPath (Join-Path $Root "PROJECT_STATUS.md") -Raw
    $match = [regex]::Match($status, "PINNED ``([^``]+)``")
    if ($match.Success) { $Godot = $match.Groups[1].Value }
}
if ($Godot -like "*Godot_v4.0*") {
    Write-Host "check_all: FAIL (Godot 4.0 refused)"
    exit 2
}
if ($Godot -and (Test-Path -LiteralPath $Godot)) {
    & $Godot --headless --path $Root --check-only --script res://tests/run_all.gd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "check_all: FAIL (godot --check-only)"
        exit $LASTEXITCODE
    }
    & $Godot --headless --path $Root --check-only --script res://src/core/log.gd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "check_all: FAIL (godot --check-only log.gd)"
        exit $LASTEXITCODE
    }
}

$statusCheck = Join-Path $Root "tools\status\status_check.py"
if (Test-Path -LiteralPath $statusCheck) {
    python $statusCheck
    if ($LASTEXITCODE -ne 0) {
        Write-Host "check_all: FAIL (status_check)"
        exit $LASTEXITCODE
    }
} else {
    Write-Host "status_check.py: not present yet (stage 04)"
}

Write-Host "check_all: PASS"
exit 0
