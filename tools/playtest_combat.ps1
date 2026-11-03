param(
    [ValidateSet('theron', 'atalanta', 'pyrrhus', 'sibyl', 'dorian')]
    [string]$Fighter = 'theron',
    [ValidateSet('idle', 'block_always', 'attack_on_interval')]
    [string]$Dummy = 'idle'
)
$projectPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$enginePath = 'D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $enginePath --path $projectPath --script res://tools/playtest_combat.gd -- --fighter $Fighter --dummy $Dummy
exit $LASTEXITCODE
