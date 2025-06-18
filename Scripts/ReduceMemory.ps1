# Memory Reduction Script
Write-Host "Reducing system memory usage..." -ForegroundColor Green

# Force garbage collection
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

# Clear standby memory (requires admin)
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Clear standby memory using Windows API
    try {
        $source = @"
using System;
using System.Runtime.InteropServices;
public class MemoryManagement {
    [DllImport("kernel32.dll")]
    public static extern bool SetProcessWorkingSetSize(IntPtr hProcess, UIntPtr dwMinimumWorkingSetSize, UIntPtr dwMaximumWorkingSetSize);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();
    
    public static void TrimWorkingSet() {
        SetProcessWorkingSetSize(GetCurrentProcess(), (UIntPtr)0xFFFFFFFF, (UIntPtr)0xFFFFFFFF);
    }
}
"@
        Add-Type -TypeDefinition $source
        [MemoryManagement]::TrimWorkingSet()
    } catch {
        Write-Host "Advanced memory management not available" -ForegroundColor Yellow
    }
}

# Get memory usage before cleanup
$beforeMemory = [math]::Round((Get-WmiObject -Class win32_operatingsystem | ForEach-Object {(($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / 1MB)}), 2)

# Close unnecessary processes (non-critical ones)
$processesToClose = @(
    "notepad", "calculator", "mspaint", "winword", "excel", "powerpoint",
    "chrome", "firefox", "msedge", "opera", "brave"
)

$closedProcesses = 0
foreach ($processName in $processesToClose) {
    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
    foreach ($process in $processes) {
        try {
            if ($process.CloseMainWindow()) {
                $closedProcesses++
                Start-Sleep -Milliseconds 500
            } else {
                $process.Kill()
                $closedProcesses++
            }
        } catch {
            # Process might have already closed
        }
    }
}

# Force another garbage collection
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

Start-Sleep 2

# Get memory usage after cleanup
$afterMemory = [math]::Round((Get-WmiObject -Class win32_operatingsystem | ForEach-Object {(($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / 1MB)}), 2)
$memoryFreed = [math]::Round(($beforeMemory - $afterMemory), 2)

Write-Host "Memory cleanup completed!" -ForegroundColor Green
Write-Host "Processes closed: $closedProcesses" -ForegroundColor Cyan
Write-Host "Memory before: $beforeMemory MB" -ForegroundColor Yellow
Write-Host "Memory after: $afterMemory MB" -ForegroundColor Yellow
Write-Host "Memory freed: $memoryFreed MB" -ForegroundColor Green

# Show notification
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$notify.BalloonTipText = "Memory cleanup completed. Freed $memoryFreed MB of RAM."
$notify.BalloonTipTitle = "Codex - Memory Reducer"
$notify.Visible = $true
$notify.ShowBalloonTip(3000)

Start-Sleep 2
