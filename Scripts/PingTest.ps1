# Ping Test Script
param([string]$Target)

if ($Target -eq "custom") {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $Target = [Microsoft.VisualBasic.Interaction]::InputBox("Enter IP address or hostname to ping:", "Custom Ping Test", "8.8.8.8")
    
    if ([string]::IsNullOrWhiteSpace($Target)) {
        exit
    }
}

$windowTitle = "Ping Test - $Target"
$cmd = "ping $Target -t"

# Create a new PowerShell window with ping running
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& {Write-Host 'Codex Ping Test' -ForegroundColor Cyan; Write-Host 'Target: $Target' -ForegroundColor Yellow; Write-Host 'Press Ctrl+C to stop' -ForegroundColor Green; Write-Host ''; $cmd}"
