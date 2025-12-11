# Configuration
param(
    [string]$StartFile = "layer0.zip",
    [int]$MaxCycles = 5,
    [string]$ScatterLocation = "",
    [switch]$EnableScatter = $false,
    [switch]$NoScatter = $false
)

# Handle scatter logic - NoScatter takes precedence
if ($NoScatter) {
    $EnableScatter = $false
}
elseif (-not $EnableScatter -and $ScatterLocation -eq "") {
    # Enable by default if no explicit flags given
    $EnableScatter = $true
}

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
    }
    else {
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

# Scatter files functionality
if ($EnableScatter -or $ScatterLocation -ne "") {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "💥 File Scattering Mode Activated!" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Ask for scatter location if not provided
    if ($ScatterLocation -eq "") {
        $ScatterLocation = "C:\Users\$env:USERNAME\"
        Write-Host "Using default scatter location: $ScatterLocation" -ForegroundColor Yellow
    }
    else {
        Write-Host "Using provided scatter location: $ScatterLocation" -ForegroundColor Yellow
    }
    
    # Validate location
    if (-not (Test-Path $ScatterLocation)) {
        Write-Host "Error: Location '$ScatterLocation' does not exist!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Target location: $ScatterLocation" -ForegroundColor Cyan
    Write-Host ""
    
    # Get all text files to scatter
    $filesToScatter = Get-ChildItem -Recurse -Filter "*.txt" -File
    
    if ($filesToScatter.Count -eq 0) {
        Write-Host "No text files found to scatter!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Found $($filesToScatter.Count) text files to scatter..." -ForegroundColor Yellow
    Write-Host ""
    
    # Get all directories in the target location (recursively)
    Write-Host "Scanning target location for folders..." -ForegroundColor Yellow
    $targetFolders = Get-ChildItem -Path $ScatterLocation -Recurse -Directory -ErrorAction SilentlyContinue
    
    if ($targetFolders.Count -eq 0) {
        Write-Host "Warning: No subfolders found. Files will be scattered in the root location." -ForegroundColor Yellow
        $targetFolders = @(Get-Item $ScatterLocation)
    }
    else {
        Write-Host "Found $($targetFolders.Count) target folders" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Starting file scattering process..." -ForegroundColor Cyan
    Write-Host "WARNING: This will move files to random locations!" -ForegroundColor Red
    Write-Host "Press Ctrl+C within 5 seconds to cancel..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Write-Host ""
    
    # Create log file
    $logFile = Join-Path (Split-Path $pwd -Parent) "scatter_$(env:USERNAME).log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== File Scattering Log ===" | Out-File -FilePath $logFile -Encoding UTF8
    "Timestamp: $timestamp" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Source: $pwd" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Target: $ScatterLocation" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Total Files: $($filesToScatter.Count)" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Scattered Files:" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "---------------" | Out-File -FilePath $logFile -Append -Encoding UTF8
    
    $scatteredCount = 0
    $random = New-Object System.Random
    
    foreach ($file in $filesToScatter) {
        # Pick a random target folder
        $randomIndex = $random.Next(0, $targetFolders.Count)
        $targetFolder = $targetFolders[$randomIndex].FullName
        
        # Generate unique filename if exists
        $targetPath = Join-Path $targetFolder $file.Name
        $counter = 1
        while (Test-Path $targetPath) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $extension = [System.IO.Path]::GetExtension($file.Name)
            $targetPath = Join-Path $targetFolder "${baseName}_${counter}${extension}"
            $counter++
        }
        
        try {
            # Copy file to target location
            Copy-Item -Path $file.FullName -Destination $targetPath -Force
            
            # Log the operation
            $logEntry = "[OK] $($file.Name) -> $targetPath"
            $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
            
            $scatteredCount++
            
            if ($scatteredCount % 10 -eq 0) {
                Write-Host "  Scattered $scatteredCount/$($filesToScatter.Count) files..." -ForegroundColor Gray
            }
        }
        catch {
            $errorEntry = "[ERROR] $($file.Name) -> $targetPath : $_"
            $errorEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
            Write-Host "  Error scattering $($file.Name): $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "✅ Scattering complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Scattering Summary:" -ForegroundColor Cyan
    Write-Host "   Files scattered: $scatteredCount" -ForegroundColor White
    Write-Host "   Target folders: $($targetFolders.Count)" -ForegroundColor White
    Write-Host "   Log file: $logFile" -ForegroundColor White
    
    # Append summary to log
    "" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "---------------" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Summary:" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Files scattered: $scatteredCount" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Target folders: $($targetFolders.Count)" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $logFile -Append -Encoding UTF8
    
    Write-Host ""
    Write-Host "💣 Files have been scattered across $ScatterLocation!" -ForegroundColor Magenta
    Write-Host "   Check scatter.log for detailed file locations." -ForegroundColor Yellow
}
