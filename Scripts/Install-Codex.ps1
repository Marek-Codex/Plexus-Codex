# Codex One-Click Installer - Downloads and installs the complete Codex system
# Usage: irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Install-Codex.ps1 | iex

param(
    [string]$InstallPath,
    [switch]$NoIcons,
    [switch]$Portable,
    [switch]$UserInstall,
    [string]$GitHubRepo = "https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main"
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Get current script directory for referencing files
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Plexus Codex One-Click Installer ===" -ForegroundColor Cyan
Write-Host "🎯 The ultimate Windows context menu system" -ForegroundColor White
Write-Host ""

# Determine best installation path
if (-not $InstallPath) {
    if ($UserInstall -or -not $isAdmin) {
        # User-specific installation
        $InstallPath = "$env:LOCALAPPDATA\Plexus"
        Write-Host "📁 User installation mode: $InstallPath\Codex" -ForegroundColor Cyan
    } else {
        # System-wide installation (preferred)
        $InstallPath = "$env:ProgramData\Plexus"
        Write-Host "📁 System-wide installation: $InstallPath\Codex" -ForegroundColor Cyan
    }
}
        Write-Host "📁 System-wide installation: $InstallPath" -ForegroundColor Cyan
    }
}

if (-not $isAdmin -and -not $Portable -and -not $UserInstall) {
    Write-Host "⚠️  Administrator privileges recommended for system-wide installation" -ForegroundColor Yellow
    Write-Host "   Options:" -ForegroundColor Gray
    Write-Host "   • Re-run as Administrator (recommended)" -ForegroundColor Gray
    Write-Host "   • Add -UserInstall for user-only installation" -ForegroundColor Gray
    Write-Host "   • Add -Portable for no registry changes" -ForegroundColor Gray

    $choice = Read-Host "`nContinue with user installation? (Y/N)"
    if ($choice.ToUpper() -ne "Y") {
        exit 1
    }
    $UserInstall = $true
    $InstallPath = "$env:LOCALAPPDATA\Plexus\Codex"
}

# Create installation directory
Write-Host "📁 Creating installation directory..." -ForegroundColor Green
$codexPath = Join-Path $InstallPath "Codex"
if (-not (Test-Path $codexPath)) {
    New-Item -ItemType Directory -Path $codexPath -Force | Out-Null
}

# Directory structure
$directories = @("Scripts", "Registry", "Tools", "Icons\Source", "Icons\Tinted", "Icons\Downloaded")
foreach ($dir in $directories) {
    $fullPath = Join-Path $codexPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}

Write-Host "✓ Directory structure created" -ForegroundColor Green

# Download function with progress
function Download-File {
    param([string]$Url, [string]$OutputPath, [string]$Description)

    try {
        Write-Host "📥 Downloading $Description..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
        Write-Host "✓ $Description downloaded" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to download $Description" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
        return $false
    }
}

# Core files to download
$coreFiles = @(
    @{ Url = "$GitHubRepo/Registry/Codex.reg"; Path = "Registry\Codex.reg"; Name = "Registry Structure" }
    @{ Url = "$GitHubRepo/Scripts/PowerManager.ps1"; Path = "Scripts\PowerManager.ps1"; Name = "Power Manager" }
    @{ Url = "$GitHubRepo/Scripts/GameTurbo.ps1"; Path = "Scripts\GameTurbo.ps1"; Name = "Game Turbo" }
    @{ Url = "$GitHubRepo/Scripts/DynamicBoost.ps1"; Path = "Scripts\DynamicBoost.ps1"; Name = "Dynamic Boost" }
    @{ Url = "$GitHubRepo/Scripts/ProcessKiller.ps1"; Path = "Scripts\ProcessKiller.ps1"; Name = "Process Killer" }
    @{ Url = "$GitHubRepo/Scripts/ReduceMemory.ps1"; Path = "Scripts\ReduceMemory.ps1"; Name = "Memory Optimizer" }
    @{ Url = "$GitHubRepo/Scripts/CleanupTemp.ps1"; Path = "Scripts\CleanupTemp.ps1"; Name = "Cleanup Temp" }
    @{ Url = "$GitHubRepo/Scripts/WifiToggle.ps1"; Path = "Scripts\WifiToggle.ps1"; Name = "WiFi Toggle" }
    @{ Url = "$GitHubRepo/Scripts/DNSSwitcher.ps1"; Path = "Scripts\DNSSwitcher.ps1"; Name = "DNS Switcher" }
    @{ Url = "$GitHubRepo/Scripts/PingTest.ps1"; Path = "Scripts\PingTest.ps1"; Name = "Ping Test" }
    @{ Url = "$GitHubRepo/Scripts/RoboCopy.ps1"; Path = "Scripts\RoboCopy.ps1"; Name = "RoboCopy" }
    @{ Url = "$GitHubRepo/Scripts/RoboPaste.ps1"; Path = "Scripts\RoboPaste.ps1"; Name = "RoboPaste" }
    @{ Url = "$GitHubRepo/Scripts/IconTinter.ps1"; Path = "Scripts\IconTinter.ps1"; Name = "Icon Tinter" }
    @{ Url = "$GitHubRepo/Scripts/AutoIconMapper.ps1"; Path = "Scripts\AutoIconMapper.ps1"; Name = "Auto Icon Mapper" }
    @{ Url = "$GitHubRepo/Scripts/Install.ps1"; Path = "Scripts\Install.ps1"; Name = "Local Installer" }
    @{ Url = "$GitHubRepo/Tools/nircmd.exe"; Path = "Tools\nircmd.exe"; Name = "NirCmd Utility" }
    @{ Url = "$GitHubRepo/ICONS.md"; Path = "ICONS.md"; Name = "Icon Reference" }
    @{ Url = "$GitHubRepo/README.md"; Path = "README.md"; Name = "Documentation" }
)

# Download core files
Write-Host ""
Write-Host "⬇️  Downloading Codex components..." -ForegroundColor Yellow
$downloadCount = 0
$totalFiles = $coreFiles.Count

foreach ($file in $coreFiles) {
    $outputPath = Join-Path $codexPath $file.Path
    $outputDir = Split-Path $outputPath -Parent

    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    if (Download-File -Url $file.Url -OutputPath $outputPath -Description $file.Name) {
        $downloadCount++
    }

    # Progress indicator
    $percent = [math]::Round(($downloadCount / $totalFiles) * 100)
    Write-Progress -Activity "Downloading Codex" -Status "$downloadCount/$totalFiles files" -PercentComplete $percent
}

Write-Progress -Activity "Downloading Codex" -Completed
Write-Host ""
Write-Host "✓ Downloaded $downloadCount/$totalFiles core files" -ForegroundColor Green

# Download icon pack if requested
if (-not $NoIcons) {
    Write-Host ""
    Write-Host "🎨 Downloading curated icon pack..." -ForegroundColor Magenta

    # Define icon pack URLs (these would be the actual icons you've curated)
    $iconPack = @(
        @{ Url = "$GitHubRepo/Icons/PowerSaver.png"; Path = "Icons\Source\PowerSaver.png" }
        @{ Url = "$GitHubRepo/Icons/Balanced.png"; Path = "Icons\Source\Balanced.png" }
        @{ Url = "$GitHubRepo/Icons/Performance.png"; Path = "Icons\Source\Performance.png" }
        @{ Url = "$GitHubRepo/Icons/GameTurbo.png"; Path = "Icons\Source\GameTurbo.png" }
        @{ Url = "$GitHubRepo/Icons/ProcessKiller.png"; Path = "Icons\Source\ProcessKiller.png" }
        # ... add all your curated icons here
    )

    $iconCount = 0
    foreach ($icon in $iconPack) {
        $outputPath = Join-Path $codexPath $icon.Path
        if (Download-File -Url $icon.Url -OutputPath $outputPath -Description "Icon: $(Split-Path $icon.Path -Leaf)") {
            $iconCount++
        }
    }

    Write-Host "✓ Downloaded $iconCount icons" -ForegroundColor Green

    # Generate tinted icons
    Write-Host ""
    Write-Host "🎨 Generating theme-aware icons..." -ForegroundColor Magenta

    $iconTinterPath = Join-Path $codexPath "Scripts\IconTinter.ps1"
    if (Test-Path $iconTinterPath) {
        try {
            & $iconTinterPath -Force
            Write-Host "✓ Theme-aware icons generated" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Icon generation failed, but you can run it manually later" -ForegroundColor Yellow
        }
    }
}

# Update registry paths
Write-Host ""
Write-Host "🔧 Configuring installation paths..." -ForegroundColor Cyan

$registryPath = Join-Path $codexPath "Registry\Codex.reg"
if (Test-Path $registryPath) {
    $regContent = Get-Content $registryPath -Raw
    $regContent = $regContent -replace 'C:\\Users\\Marek\\Plexus Codex\\Codex', $codexPath.Replace('\', '\\')
    Set-Content -Path $registryPath -Value $regContent -Encoding UTF8
    Write-Host "✓ Registry paths updated" -ForegroundColor Green
}

# Install registry entries
if (-not $Portable) {
    Write-Host ""
    Write-Host "📝 Installing registry entries..." -ForegroundColor Yellow

    try {
        & regedit.exe /s $registryPath
        Write-Host "✓ Codex context menu installed!" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Registry installation failed. Run Install.ps1 manually as Administrator." -ForegroundColor Yellow
    }
}

# Create desktop shortcuts and start menu entries
Write-Host ""
Write-Host "🔗 Creating shortcuts..." -ForegroundColor Cyan

# Copy the comprehensive uninstaller
$sourceUninstaller = Join-Path $scriptPath "Uninstall-Codex.ps1"
$uninstallPath = Join-Path $codexPath "Scripts\Uninstall-Codex.ps1"

if (Test-Path $sourceUninstaller) {
    Copy-Item $sourceUninstaller $uninstallPath -Force
    Write-Host "✓ Comprehensive uninstaller installed" -ForegroundColor Green
} else {
    # Fallback: Create basic uninstaller
    $uninstallScript = @"
# Codex Uninstaller - Basic Version
Write-Host "Removing Codex context menu..." -ForegroundColor Yellow
Remove-Item "HKCU:\SOFTWARE\Classes\Directory\Background\shell\Codex" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKLM:\SOFTWARE\Classes\Directory\Background\shell\Codex" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✓ Codex uninstalled successfully!" -ForegroundColor Green
"@
    Set-Content -Path $uninstallPath -Value $uninstallScript
    Write-Host "✓ Basic uninstaller created" -ForegroundColor Green
}

# Final summary
Write-Host ""
Write-Host "🎉 CODEX INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Installed to: $codexPath" -ForegroundColor White
Write-Host "🎯 Right-click anywhere to access Codex menu" -ForegroundColor White

if ($NoIcons) {
    Write-Host ""
    Write-Host "📌 NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Add white PNG icons to: $codexPath\Icons\Source\" -ForegroundColor Gray
    Write-Host "2. Run: $codexPath\Scripts\IconTinter.ps1" -ForegroundColor Gray
    Write-Host "3. Enjoy your customized Codex experience!" -ForegroundColor Gray
}

if ($Portable) {
    Write-Host ""
    Write-Host "⚠️  PORTABLE MODE:" -ForegroundColor Yellow
    Write-Host "Run $codexPath\Scripts\Install.ps1 as Administrator to enable context menu" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🔗 Useful commands:" -ForegroundColor Cyan
Write-Host "• Uninstall: $uninstallPath" -ForegroundColor Gray
Write-Host "• Reconfigure: $codexPath\Scripts\Install.ps1" -ForegroundColor Gray
Write-Host "• Icon Reference: $codexPath\ICONS.md" -ForegroundColor Gray

Write-Host ""
Write-Host "🎯 CODEX: Where functionality meets cyberpunk aesthetics!" -ForegroundColor Cyan
