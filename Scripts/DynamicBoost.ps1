# Dynamic Boost - Intelligent Performance Management
# Elevate to Administrator if not already
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell -Verb RunAs "-File `"$PSCommandPath`""
    exit
}

Write-Host "Starting Dynamic Boost System..." -ForegroundColor Cyan

# Power plan GUIDs
$powerPlans = @{
    "PowerSaver" = "a1841308-3541-4fab-bc81-f71556f20b4a"
    "Balanced" = "381b4222-f694-41f0-9685-ff5bb260df2e"
    "HighPerformance" = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
}

function Get-SystemLoad {
    $cpu = (Get-WmiObject win32_processor | Measure-Object -Property LoadPercentage -Average).Average
    $memory = (Get-WmiObject -Class win32_operatingsystem | ForEach-Object {"{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize)})
    $gpu = 0
    
    # Try to get GPU usage
    try {
        $gpuCounter = Get-Counter "\GPU Engine(*)\Utilization Percentage" -ErrorAction SilentlyContinue
        if ($gpuCounter) {
            $gpu = ($gpuCounter.CounterSamples | Measure-Object -Property CookedValue -Maximum).Maximum
        }
    } catch {
        # GPU counter might not be available
    }
    
    return @{
        CPU = [int]$cpu
        Memory = [int]$memory
        GPU = [int]$gpu
    }
}

function Get-RunningGames {
    $gameProcesses = @(
        "steam", "game", "unreal", "unity", "dx11", "dx12", "vulkan",
        "csgo", "valorant", "fortnite", "apex", "cod", "battlefield",
        "minecraft", "roblox", "genshin", "league", "dota2", "overwatch"
    )
    
    $runningGames = @()
    foreach ($game in $gameProcesses) {
        $processes = Get-Process -Name "*$game*" -ErrorAction SilentlyContinue
        if ($processes) {
            $runningGames += $processes
        }
    }
    return $runningGames
}

function Set-DynamicPerformance {
    param($PerformanceLevel)
    
    switch ($PerformanceLevel) {
        "Low" {
            Write-Host "Setting Power Saver mode..." -ForegroundColor Yellow
            powercfg /setactive $powerPlans["PowerSaver"]
            
            # Enable power saving features
            powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5
            powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 50
        }
        
        "Medium" {
            Write-Host "Setting Balanced mode..." -ForegroundColor Blue
            powercfg /setactive $powerPlans["Balanced"]
            
            # Moderate performance settings
            powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 20
            powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 85
        }
        
        "High" {
            Write-Host "Setting High Performance mode..." -ForegroundColor Red
            powercfg /setactive $powerPlans["HighPerformance"]
            
            # Maximum performance settings
            powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
            powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100
            
            # Boost gaming processes
            $games = Get-RunningGames
            foreach ($game in $games) {
                try {
                    $game.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                } catch {
                    # Process might have closed
                }
            }
        }
        
        "Gaming" {
            Write-Host "Activating Gaming Boost..." -ForegroundColor Green
            & "$PSScriptRoot\GameTurbo.ps1"
            return
        }
    }
    
    # Apply settings
    powercfg /setactive SCHEME_CURRENT
}

function Start-DynamicMonitoring {
    Write-Host "Dynamic Boost monitoring started. Press Ctrl+C to stop." -ForegroundColor Green
    
    $iteration = 0
    while ($true) {
        $load = Get-SystemLoad
        $games = Get-RunningGames
        $batteryStatus = (Get-WmiObject -Class Win32_Battery).BatteryStatus
        
        Write-Host "`n--- Dynamic Boost Analysis (Iteration $iteration) ---" -ForegroundColor Cyan
        Write-Host "CPU: $($load.CPU)% | Memory: $($load.Memory)% | GPU: $($load.GPU)%" -ForegroundColor White
        Write-Host "Running Games: $($games.Count)" -ForegroundColor White
        
        # Decision logic
        if ($games.Count -gt 0) {
            # Gaming detected
            if ($load.CPU -gt 70 -or $load.GPU -gt 60) {
                Set-DynamicPerformance "Gaming"
                Write-Host "→ Gaming mode activated due to high load + games running" -ForegroundColor Green
            } else {
                Set-DynamicPerformance "High"
                Write-Host "→ High performance for gaming" -ForegroundColor Green
            }
        } elseif ($load.CPU -gt 80 -or $load.Memory -gt 85) {
            # High system load
            Set-DynamicPerformance "High"
            Write-Host "→ High performance due to system load" -ForegroundColor Red
        } elseif ($load.CPU -gt 40 -or $load.Memory -gt 60) {
            # Medium load
            Set-DynamicPerformance "Medium"
            Write-Host "→ Balanced performance" -ForegroundColor Blue
        } elseif ($batteryStatus -eq 1 -and $load.CPU -lt 20) {
            # On battery and low load
            Set-DynamicPerformance "Low"
            Write-Host "→ Power saving mode (battery)" -ForegroundColor Yellow
        } else {
            # Normal operation
            Set-DynamicPerformance "Medium"
            Write-Host "→ Balanced mode (normal operation)" -ForegroundColor Blue
        }
        
        $iteration++
        Start-Sleep 10
    }
}

# Check if running with -Monitor parameter
if ($args -contains "-Monitor") {
    Start-DynamicMonitoring
} else {
    # One-time boost analysis
    $load = Get-SystemLoad
    $games = Get-RunningGames
    
    Write-Host "Current System Status:" -ForegroundColor Cyan
    Write-Host "CPU Load: $($load.CPU)%" -ForegroundColor White
    Write-Host "Memory Usage: $($load.Memory)%" -ForegroundColor White
    Write-Host "GPU Usage: $($load.GPU)%" -ForegroundColor White
    Write-Host "Games Running: $($games.Count)" -ForegroundColor White
    
    if ($games.Count -gt 0) {
        Set-DynamicPerformance "Gaming"
        Write-Host "`nGaming detected - Activating maximum performance!" -ForegroundColor Green
    } elseif ($load.CPU -gt 70 -or $load.Memory -gt 80) {
        Set-DynamicPerformance "High"
        Write-Host "`nHigh load detected - Boosting performance!" -ForegroundColor Red
    } else {
        Set-DynamicPerformance "Medium"
        Write-Host "`nOptimizing for balanced performance." -ForegroundColor Blue
    }
    
    # Notification
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notify.BalloonTipText = "Dynamic Boost analyzed your system and optimized performance automatically."
    $notify.BalloonTipTitle = "Codex - Dynamic Boost"
    $notify.Visible = $true
    $notify.ShowBalloonTip(3000)
    
    Start-Sleep 2
}
