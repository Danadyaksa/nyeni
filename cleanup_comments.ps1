# Script untuk rapikan comment di project Nyeni
Write-Host "🧹 Membersihkan comment di project..." -ForegroundColor Cyan

# Pattern comment yang mau dihapus
$patternsToRemove = @(
    '^\s*//\s*=+\s*$',
    '^\s*//\s*─+\s*$',
    '^\s*//\s*TODO',
    '^\s*//\s*FIXME',
    '^\s*//\s*DEBUG',
    '^\s*//\s*TEST',
    '^\s*//\s*HACK',
    '^\s*//\s*XXX'
)

# Proses semua file .dart
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

$totalFiles = 0
$totalLinesRemoved = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Encoding UTF8
    $newContent = @()
    $linesRemoved = 0
    
    foreach ($line in $content) {
        $shouldRemove = $false
        
        foreach ($pattern in $patternsToRemove) {
            if ($line -match $pattern) {
                $shouldRemove = $true
                $linesRemoved++
                break
            }
        }
        
        if (-not $shouldRemove) {
            $newContent += $line
        }
    }
    
    if ($linesRemoved -gt 0) {
        $newContent | Set-Content $file.FullName -Encoding UTF8
        Write-Host "  ✓ $($file.Name): $linesRemoved baris dihapus" -ForegroundColor Green
        $totalFiles++
        $totalLinesRemoved += $linesRemoved
    }
}

Write-Host "`n✨ Selesai!" -ForegroundColor Green
Write-Host "📊 Total: $totalFiles file dirapikan, $totalLinesRemoved baris comment dihapus" -ForegroundColor Cyan
