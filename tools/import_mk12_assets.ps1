Write-Host "Starting MK12 asset import..."

# Define source and destination paths (adjust if needed)
$sourceBase = "D:/05cfbdd1648afe2928109b70ab63880a4bc8f7b4 (1)/Output/Exports/MK12/Content/Disk/Char/JohnnyCage/Anim"
$destBase = "e:/zeus balls/assets/fighters"

# List of fighter directories (existing in the project)
$fighters = @("atalanta", "pyrrhus", "sibyl", "theron")

# Animation categories to copy (folders inside Anim)
$categories = @("Attack", "Special", "ThrowBreaker", "ThrowBreaker_EX", "ThrowBreaker_EX_Brutality", "ThrowBreaker_EX_Brutality_Loop", "Throw_Bwd_Hit", "Throw_Fwd_Hit", "Victory", "Intro", "Cine")

foreach ($fighter in $fighters) {
    foreach ($cat in $categories) {
        $srcPath = Join-Path $sourceBase $cat
        $destPath = Join-Path $destBase "$fighter\anims\$cat"
        if (-Not (Test-Path $destPath)) {
            New-Item -ItemType Directory -Force -Path $destPath | Out-Null
        }
        Write-Host "Copying $cat animations to $fighter..."
        Get-ChildItem -Path $srcPath -Filter "*.json" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $destPath -Force
        }
    }
}

Write-Host "Asset import completed."
