# Process Killer Script
param([string]$Category)

$processGroups = @{
    "browsers" = @("chrome", "firefox", "msedge", "opera", "brave", "vivaldi", "safari", "iexplore")
    "office" = @("winword", "excel", "powerpoint", "outlook", "onenote", "msaccess", "visio", "project")
    "gaming" = @("steam", "origin", "epicgameslauncher", "uplay", "battlenet", "gog", "riotclientservices", "riotclientux", "discord")
}

if (-not $processGroups.ContainsKey($Category)) {
    Write-Host "Unknown category: $Category" -ForegroundColor Red
    exit
}

$processesToKill = $processGroups[$Category]
$killedCount = 0
$killedProcesses = @()

Write-Host "Killing $Category processes..." -ForegroundColor Yellow

foreach ($processName in $processesToKill) {
    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
    foreach ($process in $processes) {
        try {
            $processTitle = $process.ProcessName
            if ($process.CloseMainWindow()) {
                Write-Host "Gracefully closed: $processTitle" -ForegroundColor Green
                $killedCount++
                $killedProcesses += $processTitle
                Start-Sleep -Milliseconds 500
            } else {
                $process.Kill()
                Write-Host "Force killed: $processTitle" -ForegroundColor Red
                $killedCount++
                $killedProcesses += $processTitle
            }
        } catch {
            Write-Host "Could not kill: $processTitle" -ForegroundColor Yellow
        }
    }
}

# Show notification
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info

if ($killedCount -gt 0) {
    $notify.BalloonTipText = "Killed $killedCount $Category processes: $($killedProcesses -join ', ')"
    $notify.BalloonTipTitle = "Codex - Process Killer"
    Write-Host "Successfully killed $killedCount processes" -ForegroundColor Green
} else {
    $notify.BalloonTipText = "No $Category processes were running"
    $notify.BalloonTipTitle = "Codex - Process Killer"
    Write-Host "No $Category processes found running" -ForegroundColor Cyan
}

$notify.Visible = $true
$notify.ShowBalloonTip(3000)
Start-Sleep 1
