# Codex Installation Script
# Run as Administrator

Write-Host "=== Plexus Codex Installation ===" -ForegroundColor Cyan
Write-Host "This will install the Codex context menu system." -ForegroundColor White

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$codexPath = $scriptPath # Assuming Install.ps1 is in the root of Codex directory
$regFilePath = Join-Path $scriptPath "Registry\Codex.reg"

Write-Host "`nInstalling Codex..." -ForegroundColor Green

try {
    # Generate accent-colored icons first
    Write-Host "Generating custom icons..." -ForegroundColor Cyan
    $iconScript = Join-Path $scriptPath "Scripts\IconTinter.ps1"
    if (Test-Path $iconScript) {
        & $iconScript -Force
        Write-Host "✓ Custom icons generated" -ForegroundColor Green
    } else {
        Write-Host "⚠ Icon script not found, using default icons" -ForegroundColor Yellow
    }

    # Modify and import registry file
    $originalRegFilePath = Join-Path $scriptPath "Registry\Codex.reg"
    $modifiedRegFilePath = Join-Path $scriptPath "Registry\Codex_mod.reg"
    $placeholderPath = "C:\\Users\\Marek\\Plexus Codex\\Codex" # Double backslashes for regex and PowerShell string
    
    if (Test-Path $originalRegFilePath) {
        Write-Host "Modifying registry file for current installation path..." -ForegroundColor Cyan
        $regContent = Get-Content $originalRegFilePath -Raw
        # Escape $codexPath for regex replacement (especially backslashes)
        $escapedCodexPath = ($codexPath -replace '\', '\\')
        $regContent = $regContent -replace [regex]::Escape($placeholderPath), $escapedCodexPath
        Set-Content -Path $modifiedRegFilePath -Value $regContent -Encoding UTF8
        $regFilePath = $modifiedRegFilePath # Update regFilePath to use the modified file
        Write-Host "✓ Registry file paths updated to: $codexPath" -ForegroundColor Green
    } else {
        Write-Host "✗ Original registry file not found at: $originalRegFilePath" -ForegroundColor Red
        exit
    }

    if (Test-Path $regFilePath) {
        Start-Process "regedit.exe" -ArgumentList "/s", "`"$regFilePath`"" -Wait
        Write-Host "✓ Registry entries imported successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Registry file not found: $regFilePath" -ForegroundColor Red
        exit
    }
    
    # Set execution policy for scripts
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "✓ PowerShell execution policy set" -ForegroundColor Green
    
    # Test if scripts are accessible
    $scriptsPath = Join-Path $scriptPath "Scripts"
    if (Test-Path $scriptsPath) {
        $scriptFiles = Get-ChildItem -Path $scriptsPath -Filter "*.ps1"
        Write-Host "✓ Found $($scriptFiles.Count) PowerShell scripts" -ForegroundColor Green
    } else {
        Write-Host "✗ Scripts folder not found" -ForegroundColor Red
        exit
    }
      Write-Host "`n=== Installation Complete ===" -ForegroundColor Green
    Write-Host "Codex has been installed successfully!" -ForegroundColor White
    Write-Host "`nTo use:" -ForegroundColor Cyan
    Write-Host "• Right-click on desktop or in any folder" -ForegroundColor White
    Write-Host "• Look for '📚 Codex' in the context menu" -ForegroundColor White
    Write-Host "`nFeatures available:" -ForegroundColor Cyan
    Write-Host "• Power Options (including GameTurbo and Dynamic Boost)" -ForegroundColor White
    Write-Host "• System Control (restart, sleep, show desktop, etc.)" -ForegroundColor White
    Write-Host "• Audio & Network (volume, Wi-Fi toggle, DNS flush)" -ForegroundColor White
    Write-Host "• Quick Access (system folders, admin tools)" -ForegroundColor White
    Write-Host "• Process Management (kill browsers, office, gaming)" -ForegroundColor White
    Write-Host "• Network Tools (ping tests)" -ForegroundColor White
    Write-Host "• System Cleanup (temp files, memory reduction)" -ForegroundColor White
    Write-Host "• Universal RoboCopy/RoboPaste" -ForegroundColor White

    Write-Host "
💡 For future installations or updates, consider using the advanced installer:" -ForegroundColor Yellow
    Write-Host "   '$scriptPath\Scripts\Install-Codex.ps1'" -ForegroundColor White
    Write-Host "   It offers more features like automatic downloads and system-wide installation." -ForegroundColor White
    
} catch {
    Write-Host "✗ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
}

if (Test-Path $modifiedRegFilePath) {
    Remove-Item $modifiedRegFilePath -Force
}

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
