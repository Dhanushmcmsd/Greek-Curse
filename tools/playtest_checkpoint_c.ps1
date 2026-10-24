$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root
$Godot = "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $Godot)) { throw "Pinned Godot executable not found: $Godot" }
$env:APPDATA = Join-Path $Root "build/runtime"
& $Godot --path $Root -- --user-profile (Join-Path $Root "build/playtest_profile")
exit $LASTEXITCODE
