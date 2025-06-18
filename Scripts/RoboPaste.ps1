# RoboPaste Script - Paste previously copied files/folders
param([string]$DestinationPath)

if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
    Write-Host "No destination path provided" -ForegroundColor Red
    exit
}

# Check for stored copy information
$copyInfoPath = "$env:TEMP\Codex_RoboCopy.json"

if (-not (Test-Path $copyInfoPath)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("No RoboCopy operation found. Please use RoboCopy first.", "Codex - RoboPaste", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    exit
}

try {
    $copyInfo = Get-Content $copyInfoPath | ConvertFrom-Json
    $sourcePath = $copyInfo.SourcePath
    $sourceType = $copyInfo.Type
    $timestamp = $copyInfo.Timestamp
    
    if (-not (Test-Path $sourcePath)) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Source path no longer exists: $sourcePath", "Codex - RoboPaste", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    }
    
    $sourceName = Split-Path $sourcePath -Leaf
    $fullDestination = Join-Path $DestinationPath $sourceName
    
    Write-Host "Starting RoboPaste operation..." -ForegroundColor Green
    Write-Host "Source: $sourcePath" -ForegroundColor Cyan
    Write-Host "Destination: $fullDestination" -ForegroundColor Cyan
    Write-Host "Original copy time: $timestamp" -ForegroundColor Yellow
    
    if ($sourceType -eq "Directory") {
        # Directory paste with RoboCopy
        $roboArgs = @(
            "`"$sourcePath`"",
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
        # Single file paste
        try {
            Copy-Item $sourcePath $fullDestination -Force
            Write-Host "File pasted successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Error pasting file: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Show completion notification
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notify.BalloonTipText = "RoboPaste completed successfully."
    $notify.BalloonTipTitle = "Codex - RoboPaste"
    $notify.Visible = $true
    $notify.ShowBalloonTip(3000)
    
} catch {
    Write-Host "Error reading copy information: $($_.Exception.Message)" -ForegroundColor Red
}
