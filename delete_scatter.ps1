# Delete Scattered Files - Cleanup Script
param(
    [string]$LogFile = "scatter_$(env:USERNAME).log",
    [switch]$WhatIf = $false,
    [switch]$Force = $false
)

Write-Host ""
Write-Host "Delete Scattered Files Cleanup" -ForegroundColor Red
Write-Host "======================================" -ForegroundColor Red
Write-Host ""

if (-not (Test-Path $LogFile)) {
    Write-Host "Error: Log file not found: $LogFile" -ForegroundColor Red
    exit 1
}

Write-Host "Reading log file: $LogFile" -ForegroundColor Cyan
Write-Host ""

$logContent = Get-Content $LogFile -Encoding UTF8
$filePaths = @()

foreach ($line in $logContent) {
    if ($line -match '^\[OK\].*->(.+)$') {
        $filePath = $matches[1].Trim()
        if (Test-Path $filePath) {
            $filePaths += $filePath
        }
    }
}

if ($filePaths.Count -eq 0) {
    Write-Host "No scattered files found in the log." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($filePaths.Count) scattered files" -ForegroundColor Green
Write-Host ""

Write-Host "Sample files to be deleted:" -ForegroundColor Yellow
$filePaths | Select-Object -First 5 | ForEach-Object {
    Write-Host "  $([char]8226) $_" -ForegroundColor Gray
}
if ($filePaths.Count -gt 5) {
    Write-Host "  ... and $($filePaths.Count - 5) more files" -ForegroundColor Gray
}
Write-Host ""

$totalSize = 0
foreach ($file in $filePaths) {
    if (Test-Path $file) {
        $totalSize += (Get-Item $file).Length
    }
}
$sizeMB = [math]::Round($totalSize / 1MB, 2)
$sizeGB = [math]::Round($totalSize / 1GB, 3)

if ($sizeGB -gt 0.1) {
    Write-Host "Total size to be freed: $sizeGB GB" -ForegroundColor Cyan
}
else {
    Write-Host "Total size to be freed: $sizeMB MB" -ForegroundColor Cyan
}
Write-Host ""

if ($WhatIf) {
    Write-Host "WhatIf mode - No files will be deleted" -ForegroundColor Yellow
    Write-Host "Remove -WhatIf parameter to actually delete files" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

if (-not $Force) {
    Write-Host "WARNING: This will permanently delete $($filePaths.Count) files!" -ForegroundColor Red
    Write-Host ""
    $confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
    
    if ($confirmation -ne "yes") {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

Write-Host "Deleting scattered files..." -ForegroundColor Red
Write-Host ""

$deletedCount = 0
$failedCount = 0
$failedFiles = @()

foreach ($filePath in $filePaths) {
    try {
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force -ErrorAction Stop
            $deletedCount++
            
            if ($deletedCount % 50 -eq 0) {
                Write-Host "  Deleted $deletedCount/$($filePaths.Count) files..." -ForegroundColor Gray
            }
        }
    }
    catch {
        $failedCount++
        $failedFiles += $filePath
        Write-Host "  Failed to delete: $filePath" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Cleanup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "   Files deleted: $deletedCount" -ForegroundColor White
Write-Host "   Files failed: $failedCount" -ForegroundColor White

if ($failedCount -gt 0) {
    Write-Host ""
    Write-Host "Failed files:" -ForegroundColor Red
    foreach ($file in $failedFiles) {
        Write-Host "  $([char]8226) $file" -ForegroundColor Gray
    }
}

Write-Host ""
