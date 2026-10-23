$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root
$Blender = if ($env:BLENDER_BIN) { $env:BLENDER_BIN } else { 'D:\blender\blender.exe' }
& $Blender --background --python tools/blender/build_all.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/validate/validate_assets.py
exit $LASTEXITCODE
