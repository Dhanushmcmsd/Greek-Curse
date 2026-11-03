$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Godot = 'D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe'
if ($env:GODOT_BIN) { $Godot = $env:GODOT_BIN }
if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot not found: $Godot" }
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot '.godot/global_script_class_cache.cfg'))) {
    & $Godot --headless --path $ProjectRoot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed; see console output.' }
}
Start-Process -FilePath $Godot -ArgumentList @('--path', ('"' + $ProjectRoot + '"'), 'res://scenes/match/match_prototype.tscn') -WorkingDirectory $ProjectRoot
