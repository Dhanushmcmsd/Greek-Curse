param([switch]$Main)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root
$env:APPDATA = Join-Path $Root "build/runtime"
$Godot = "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$Scene = if ($Main) { "res://scenes/match/match_prototype.tscn" } else { "res://scenes/debug/regrow_lab.tscn" }
& $Godot --path $Root $Scene
exit $LASTEXITCODE
