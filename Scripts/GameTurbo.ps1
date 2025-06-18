# GameTurbo - Ultimate Gaming Performance Mode
# Elevate to Administrator if not already
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell -Verb RunAs "-File `"$PSCommandPath`""
    exit
}

Write-Host "Activating GameTurbo Mode..." -ForegroundColor Green

# Set High Performance Power Plan
$highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
powercfg /setactive $highPerfGuid

# Disable CPU throttling
powercfg /setacvalueindex $highPerfGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 0
powercfg /setdcvalueindex $highPerfGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 0

# Set CPU minimum state to 100%
powercfg /setacvalueindex $highPerfGuid 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
powercfg /setdcvalueindex $highPerfGuid 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100

# Set CPU maximum state to 100%
powercfg /setacvalueindex $highPerfGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100
powercfg /setdcvalueindex $highPerfGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100

# Disable Windows Game Mode interference
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f

# Set high priority for gaming processes
$gamingProcesses = @("steam", "origin", "uplay", "epicgameslauncher", "battlenet", "gog", "riotclientservices")
foreach ($process in $gamingProcesses) {
    Get-Process -Name $process -ErrorAction SilentlyContinue | ForEach-Object {
        $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
    }
}

# Disable Windows Update during gaming
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f

# Disable unnecessary services temporarily
$servicesToStop = @(
    "WSearch",      # Windows Search
    "SysMain",      # Superfetch
    "Themes",       # Themes
    "TabletInputService", # Tablet Input
    "Fax"           # Fax Service
)

foreach ($service in $servicesToStop) {
    try {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {
        # Service might not exist or already stopped
    }
}

# Set network adapter to high performance
Get-NetAdapter | ForEach-Object {
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Power Saving Mode" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
}

# Disable Nagle's algorithm for gaming
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TCPNoDelay" /t REG_DWORD /d 1 /f

# Clear standby memory
if (Get-Command "EmptyStandbyList" -ErrorAction SilentlyContinue) {
    EmptyStandbyList
}

# Force garbage collection
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

# Kill unnecessary background processes
$processesToKill = @(
    "skype", "discord", "spotify", "chrome", "firefox", "msedge", 
    "teams", "slack", "zoom", "dropbox", "onedrive"
)

foreach ($proc in $processesToKill) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Apply changes
powercfg /setactive $highPerfGuid

# Notification
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$notify.BalloonTipText = "GameTurbo Mode Activated! System optimized for gaming."
$notify.BalloonTipTitle = "Codex - GameTurbo"
$notify.Visible = $true
$notify.ShowBalloonTip(3000)

Write-Host "GameTurbo Mode Activated Successfully!" -ForegroundColor Green
Start-Sleep 2
