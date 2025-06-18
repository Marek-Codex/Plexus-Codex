# Cleanup Temporary Files Script
Write-Host "Starting temporary files cleanup..." -ForegroundColor Green

$cleanupPaths = @(
    "$env:TEMP\*",
    "$env:LOCALAPPDATA\Temp\*",
    "$env:WINDIR\Temp\*",
    "$env:WINDIR\Prefetch\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
    "$env:APPDATA\Microsoft\Windows\Recent\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\WebCache\*"
)

$totalFreed = 0
$filesDeleted = 0

foreach ($path in $cleanupPaths) {
    Write-Host "Cleaning: $(Split-Path $path -Parent)" -ForegroundColor Cyan
    
    try {
        $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            try {
                $size = if ($item.PSIsContainer) { 0 } else { $item.Length }
                Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                $totalFreed += $size
                $filesDeleted++
            } catch {
                # File might be in use, skip it
            }
        }
    } catch {
        Write-Host "  Could not access $(Split-Path $path -Parent)" -ForegroundColor Yellow
    }
}

# Clean Windows Update cache (requires admin)
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    try {
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        $wuCache = "$env:WINDIR\SoftwareDistribution\Download\*"
        $wuItems = Get-ChildItem -Path $wuCache -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($item in $wuItems) {
            try {
                $size = if ($item.PSIsContainer) { 0 } else { $item.Length }
                Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                $totalFreed += $size
                $filesDeleted++
            } catch {
                # Skip locked files
            }
        }
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        Write-Host "Windows Update cache cleaned" -ForegroundColor Green
    } catch {
        Write-Host "Could not clean Windows Update cache" -ForegroundColor Yellow
    }
}

# Run Disk Cleanup
try {
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
    Write-Host "System disk cleanup completed" -ForegroundColor Green
} catch {
    Write-Host "Could not run disk cleanup" -ForegroundColor Yellow
}

$totalFreedMB = [math]::Round(($totalFreed / 1MB), 2)

Write-Host "`nCleanup completed!" -ForegroundColor Green
Write-Host "Files deleted: $filesDeleted" -ForegroundColor Cyan
Write-Host "Space freed: $totalFreedMB MB" -ForegroundColor Green

# Show notification
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$notify.BalloonTipText = "Cleanup completed. Deleted $filesDeleted files and freed $totalFreedMB MB."
$notify.BalloonTipTitle = "Codex - Temp Cleanup"
$notify.Visible = $true
$notify.ShowBalloonTip(3000)

Start-Sleep 2
