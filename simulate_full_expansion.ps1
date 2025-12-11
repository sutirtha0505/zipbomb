# Configuration
param(
    [string]$StartFile = "layer0.zip",
    [int]$MaxCycles = 5
)

Write-Host ""
Write-Host " Starting FULL Expansion Simulation (keeping all files)..." -ForegroundColor Cyan
Write-Host "---------------------------------------------" -ForegroundColor Cyan

if (-not (Test-Path $StartFile)) {
    Write-Host "Error: $StartFile not found. Run the C generator first." -ForegroundColor Red
    exit 1
}

$outputDir = "full_expansion_zone"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Copy-Item $StartFile -Destination $outputDir -Force
Set-Location $outputDir

$currentCycle = 0

while ($true) {
    $zipFiles = Get-ChildItem -Recurse -Filter "*.zip" | Where-Object { $_.Name -notlike "*.extracted" }
    
    if ($zipFiles.Count -eq 0) {
        break
    }
    
    if ($currentCycle -ge $MaxCycles) {
        Write-Host " Safety limit reached ($MaxCycles cycles). Stopping simulation." -ForegroundColor Yellow
        break
    }
    
    Write-Host "[Cycle $currentCycle] Found $($zipFiles.Count) archives. Extracting..." -ForegroundColor Yellow
    
    foreach ($zipFile in $zipFiles) {
        $dirName = $zipFile.BaseName + "_contents"
        $dirPath = Join-Path $zipFile.DirectoryName $dirName
        
        if (-not (Test-Path $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath | Out-Null
        }
        
        Write-Host "   Extracting $($zipFile.Name) into $dirName..." -ForegroundColor Gray
        
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile.FullName, $dirPath)
            
            $newName = $zipFile.FullName + ".extracted"
            Rename-Item $zipFile.FullName $newName
        }
        catch {
            Write-Host "    Warning: Error extracting $($zipFile.Name): $_" -ForegroundColor Red
        }
    }
    
    $allFiles = Get-ChildItem -Recurse -File
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $sizeGB = [math]::Round($totalSize / 1GB, 3)
    $sizeMB = [math]::Round($totalSize / 1MB, 2)
    
    if ($sizeGB -gt 0.1) {
        $sizeStr = "$sizeGB GB"
    } else {
        $sizeStr = "$sizeMB MB"
    }
    
    $zipRemaining = (Get-ChildItem -Recurse -Filter "*.zip" | Where-Object { $_.Name -notlike "*.extracted" }).Count
    $txtCount = (Get-ChildItem -Recurse -Filter "*.txt").Count
    
    Write-Host "    Status: Folder size is now $sizeStr" -ForegroundColor Cyan
    Write-Host "    Files: $txtCount text files, $zipRemaining zips remaining" -ForegroundColor Cyan
    
    $currentCycle++
    Write-Host "---------------------------------------------" -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host " Simulation complete." -ForegroundColor Green
Write-Host ""
Write-Host " Final Statistics:" -ForegroundColor Cyan

$allFiles = Get-ChildItem -Recurse -File
$txtFiles = Get-ChildItem -Recurse -Filter "*.txt"
$extractedZips = Get-ChildItem -Recurse -Filter "*.extracted"
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
$sizeGB = [math]::Round($totalSize / 1GB, 3)

Write-Host "   Total files: $($allFiles.Count)" -ForegroundColor White
Write-Host "   Text files: $($txtFiles.Count)" -ForegroundColor White
Write-Host "   Processed zips: $($extractedZips.Count)" -ForegroundColor White
Write-Host "   Folder size: $sizeGB GB" -ForegroundColor White
Write-Host ""
$pwd = Get-Location
Write-Host "   Location: $pwd" -ForegroundColor Gray
