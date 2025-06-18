# Power Manager - Enhanced Power Plan Management with Custom Plan Creation
param([string]$PowerPlan)

# Elevate to Administrator if not already
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell -Verb RunAs "-File `"$PSCommandPath`" -PowerPlan `"$PowerPlan`""
    exit
}

# Standard Windows power plan GUIDs
$standardPlans = @{
    "PowerSaver" = "a1841308-3541-4fab-bc81-f71556f20b4a"
    "Balanced" = "381b4222-f694-41f0-9685-ff5bb260df2e"
    "HighPerformance" = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
}

function Ensure-PowerPlan {
    param([string]$PlanName, [string]$PlanGuid)
    
    # Check if plan exists
    $existingPlans = powercfg /list
    if ($existingPlans -match $PlanGuid) {
        Write-Host "✓ $PlanName power plan already exists" -ForegroundColor Green
        return $PlanGuid
    }
    
    # Create plan if it doesn't exist
    Write-Host "Creating $PlanName power plan..." -ForegroundColor Yellow
    
    switch ($PlanName) {
        "PowerSaver" {
            powercfg /duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a $PlanGuid | Out-Null
        }
        "HighPerformance" {
            powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c $PlanGuid | Out-Null
        }
        default {
            powercfg /duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e $PlanGuid | Out-Null
        }
    }
    
    powercfg /changename $PlanGuid $PlanName | Out-Null
    Write-Host "✓ Created $PlanName power plan" -ForegroundColor Green
    return $PlanGuid
}

function Switch-PowerPlan {
    param([string]$PlanName, [string]$PlanGuid)
    
    # Ensure the plan exists
    $actualGuid = Ensure-PowerPlan -PlanName $PlanName -PlanGuid $PlanGuid
    
    # Switch to the plan
    powercfg /setactive $actualGuid
    
    # Verify the switch
    $currentPlan = powercfg /getactivescheme
    if ($currentPlan -match $actualGuid) {
        Write-Host "✓ Switched to $PlanName power plan" -ForegroundColor Green
        
        # Show notification
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $notify = New-Object System.Windows.Forms.NotifyIcon
            $notify.Icon = [System.Drawing.SystemIcons]::Information
            $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
            $notify.BalloonTipText = "Power plan changed to $PlanName"
            $notify.BalloonTipTitle = "Codex - Power Manager"
            $notify.Visible = $true
            $notify.ShowBalloonTip(3000)
            
            # Cleanup
            Start-Sleep 3
            $notify.Dispose()
        }
        catch {
            # Notification failed, but power plan switch succeeded
        }
        
        return $true
    } else {
        Write-Host "✗ Failed to switch to $PlanName" -ForegroundColor Red
        return $false
    }
}

# Main execution
if ($standardPlans.ContainsKey($PowerPlan)) {
    $success = Switch-PowerPlan -PlanName $PowerPlan -PlanGuid $standardPlans[$PowerPlan]
    exit $(if ($success) { 0 } else { 1 })
} else {
    Write-Host "Unknown power plan: $PowerPlan" -ForegroundColor Red
    Write-Host "Available plans: $($standardPlans.Keys -join ', ')" -ForegroundColor Gray
    exit 1
}
