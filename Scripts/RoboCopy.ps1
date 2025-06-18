# RoboCopy Script - Copy files/folders
param([string]$SourcePath)

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    Write-Host "No source path provided" -ForegroundColor Red
    exit
}

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# Get destination path
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select destination folder for RoboCopy"
$folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer

if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $destinationPath = $folderBrowser.SelectedPath
} else {
    exit
}

# Store the copy operation for RoboPaste
$copyInfoPath = "$env:TEMP\Codex_RoboCopy.json"
$copyInfo = @{
    SourcePath = $SourcePath
    Timestamp = Get-Date
    Type = if (Test-Path $SourcePath -PathType Container) { "Directory" } else { "File" }
} | ConvertTo-Json

Set-Content -Path $copyInfoPath -Value $copyInfo

# Perform the copy
$sourceName = Split-Path $SourcePath -Leaf
$fullDestination = Join-Path $destinationPath $sourceName

Write-Host "Starting RoboCopy operation..." -ForegroundColor Green
Write-Host "Source: $SourcePath" -ForegroundColor Cyan
Write-Host "Destination: $fullDestination" -ForegroundColor Cyan

if (Test-Path $SourcePath -PathType Container) {
    # Directory copy with RoboCopy
    $roboArgs = @(
        "`"$SourcePath`"",
        "`"$fullDestination`"",
        "/E",          # Copy subdirectories including empty ones
        "/COPY:DAT",   # Copy Data, Attributes, and Timestamps
        "/R:3",        # Retry 3 times
        "/W:1",        # Wait 1 second between retries
        "/MT:8",       # Multi-threaded (8 threads)
        "/V"           # Verbose output
    )
    
    Start-Process "robocopy" -ArgumentList $roboArgs -Wait -WindowStyle Normal
} else {
    # Single file copy
    try {
        Copy-Item $SourcePath $fullDestination -Force
        Write-Host "File copied successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Error copying file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Show completion notification
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$notify.BalloonTipText = "RoboCopy completed. Files copied to clipboard for RoboPaste."
$notify.BalloonTipTitle = "Codex - RoboCopy"
$notify.Visible = $true
$notify.ShowBalloonTip(3000)
