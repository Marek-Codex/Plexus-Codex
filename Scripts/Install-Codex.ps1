# Codex One-Click Installer - Downloads and installs the complete Codex system
# Usage: irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Install-Codex.ps1 | iex

param(
    [string]$InstallPath,
    [switch]$NoIcons,
    [switch]$Portable,
    [switch]$UserInstall,
    [string]$GitHubRepoParam = "https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main"
)

# Prioritize environment variable, then parameter, then default
$GitHubRepo = $env:CODEX_GITHUB_REPO
if (-not $GitHubRepo) {
    $GitHubRepo = $GitHubRepoParam
}
if (-not $GitHubRepo) {
    $GitHubRepo = "https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main"
    Write-Host "⚠️ GitHubRepo not found in env var or param, using default: $GitHubRepo" -ForegroundColor Yellow
}

# Final check to ensure $GitHubRepo is not empty
if (-not $GitHubRepo) {
    $GitHubRepo = "https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main"
    Write-Host "⚠️ GitHubRepo was empty, using default: $GitHubRepo" -ForegroundColor Yellow
}

# Check for environment variables if parameters not provided (for remote execution)
# if (-not $GitHubRepo -and $env:CODEX_GITHUB_REPO) { $GitHubRepo = $env:CODEX_GITHUB_REPO } # Old logic replaced
if (-not $InstallPath -and $env:CODEX_INSTALL_PATH) { $InstallPath = $env:CODEX_INSTALL_PATH }
if (-not $UserInstall -and $env:CODEX_USER_INSTALL -eq "true") { $UserInstall = $true }

# Detect if running remotely (no proper script path)
$isRemoteExecution = $true
$scriptPath = $null

# For remote execution, we don't need the script path
# All operations will be based on the target installation directory

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

Write-Host "=== Plexus Codex One-Click Installer ===" -ForegroundColor Cyan
Write-Host "🎯 The ultimate Windows context menu system" -ForegroundColor White
Write-Host ""

# Debug: Show parameter values
Write-Host "DEBUG: Parameter values received:" -ForegroundColor Magenta
Write-Host "  InstallPath: '$InstallPath'" -ForegroundColor Gray
Write-Host "  UserInstall: $UserInstall" -ForegroundColor Gray
Write-Host "  GitHubRepo: '$GitHubRepo'" -ForegroundColor Gray
Write-Host "  isAdmin: $isAdmin" -ForegroundColor Gray
Write-Host ""

# Determine best installation path
if (-not $InstallPath) {
    if ($UserInstall -or -not $isAdmin) {
        # User-specific installation
        $InstallPath = "$env:LOCALAPPDATA\Plexus"
        Write-Host "📁 User installation mode: $InstallPath\Codex" -ForegroundColor Cyan
    }
    else {
        # System-wide installation (preferred)
        $InstallPath = "$env:ProgramData\Plexus"
        Write-Host "📁 System-wide installation: $InstallPath\Codex" -ForegroundColor Cyan
    }
}
else {
    # Custom installation path provided
    $InstallPath = $InstallPath.TrimEnd('\')
    Write-Host "📁 Custom installation path: $InstallPath\Codex" -ForegroundColor Cyan
}

# Validate InstallPath
if (-not $InstallPath) {
    Write-Host "❌ ERROR: InstallPath could not be determined. Please specify -InstallPath or set CODEX_INSTALL_PATH." -ForegroundColor Red
    exit 1
}
$InstallPath = $InstallPath.TrimEnd('\').TrimEnd('/') # Ensure no trailing slash (Windows or Unix-style)
if (-not $InstallPath) { # Check again after trimming, in case it was just slashes
    Write-Host "❌ ERROR: InstallPath became empty after trimming trailing slashes. Please provide a valid path." -ForegroundColor Red
    exit 1
}
Write-Host "✓ InstallPath validated: $InstallPath" -ForegroundColor Green


if (-not $isAdmin -and -not $Portable -and -not $UserInstall) {
    Write-Host "⚠️  Administrator privileges recommended for system-wide installation" -ForegroundColor Yellow
    Write-Host "   Options:" -ForegroundColor Gray
    Write-Host "   • Re-run as Administrator (recommended)" -ForegroundColor Gray
    Write-Host "   • Add -UserInstall for user-only installation" -ForegroundColor Gray
    Write-Host "   • Add -Portable for no registry changes" -ForegroundColor Gray    $choice = Read-Host "`nContinue with user installation? (Y/N)"
    if ($choice.ToUpper() -ne "Y") {
        exit 1
    }
    $UserInstall = $true
    $InstallPath = "$env:LOCALAPPDATA\Plexus"
}

# Define and validate codexPath
$codexPath = Join-Path $InstallPath "Codex"
if (-not $codexPath) {
    Write-Host "❌ ERROR: codexPath could not be constructed. InstallPath was '$InstallPath'." -ForegroundColor Red
    exit 1
}
Write-Host "✓ CodexPath determined: $codexPath" -ForegroundColor Green

# Create installation directory with error handling
Write-Host "📁 Creating installation directory structure..." -ForegroundColor Green
try {
    $parentDir = Split-Path $codexPath
    if (-not (Test-Path $parentDir)) {
        Write-Host "  Creating parent directory: $parentDir" -ForegroundColor Gray
        New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop | Out-Null
    }
    if (-not (Test-Path $codexPath)) {
        Write-Host "  Creating Codex directory: $codexPath" -ForegroundColor Gray
        New-Item -ItemType Directory -Path $codexPath -Force -ErrorAction Stop | Out-Null
    }
    Write-Host "✓ Installation directory structure created/verified." -ForegroundColor Green
}
catch {
    Write-Host "❌ ERROR: Failed to create installation directory '$codexPath'. Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please check permissions and path validity." -ForegroundColor Yellow
    exit 1
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

    $maxRetries = 3
    $retryDelaySeconds = 5
    $attempt = 0

    while ($attempt -lt $maxRetries) {
        $attempt++
        try {
            Write-Host "📥 Downloading $Description (Attempt $attempt/$maxRetries)..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
            Write-Host "✓ $Description downloaded successfully" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "✗ Failed to download $Description (Attempt $attempt/$maxRetries)" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
            if ($attempt -lt $maxRetries) {
                Write-Host "⏱️ Retrying in $retryDelaySeconds seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $retryDelaySeconds
            }
            else {
                Write-Host "❌ All retries failed for $Description." -ForegroundColor Red
                return $false
            }
        }
    }
    return $false # Should not be reached if logic is correct
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
    @{ Url = "$GitHubRepo/Tools/nircmd.exe"; Path = "Tools\nircmd.exe"; Name = "NirCmd Utility" }
    @{ Url = "$GitHubRepo/ICONS.md"; Path = "ICONS.md"; Name = "Icon Reference" }
    @{ Url = "$GitHubRepo/README.md"; Path = "README.md"; Name = "Documentation" }
    @{ Url = "$GitHubRepo/Scripts/Uninstall-Codex.ps1"; Path = (Join-Path 'Scripts' 'Uninstall-Codex.ps1'); Name = "Comprehensive Uninstaller" }
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
    else {
        # Check if the failed download is a critical file
        $criticalCoreFiles = @(
            "Registry Structure", "Power Manager", "Game Turbo", "Dynamic Boost",
            "Process Killer", "Memory Optimizer", "Cleanup Temp", "WiFi Toggle",
            "DNS Switcher", "Ping Test", "RoboCopy", "RoboPaste",
            "Icon Tinter", "NirCmd Utility", "Comprehensive Uninstaller"
        )
        if ($file.Name -in $criticalCoreFiles) {
            Write-Host "❌ Critical file $($file.Name) failed to download. Installation cannot continue." -ForegroundColor Red
            exit 1
        }
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
        @{ Url = "$GitHubRepo/Icons/Source/AlwaysOnTop.png"; Path = "Icons\Source\AlwaysOnTop.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Balanced.png"; Path = "Icons\Source\Balanced.png" },
        @{ Url = "$GitHubRepo/Icons/Source/BrandIcon.png"; Path = "Icons\Source\BrandIcon.png" },
        @{ Url = "$GitHubRepo/Icons/Source/CMD.png"; Path = "Icons\Source\CMD.png" },
        @{ Url = "$GitHubRepo/Icons/Source/CleanupTemp.png"; Path = "Icons\Source\CleanupTemp.png" },
        @{ Url = "$GitHubRepo/Icons/Source/CustomPing.png"; Path = "Icons\Source\CustomPing.png" },
        @{ Url = "$GitHubRepo/Icons/Source/DNSSwitcher.png"; Path = "Icons\Source\DNSSwitcher.png" },
        @{ Url = "$GitHubRepo/Icons/Source/DeviceManager.png"; Path = "Icons\Source\DeviceManager.png" },
        @{ Url = "$GitHubRepo/Icons/Source/DynamicBoost.png"; Path = "Icons\Source\DynamicBoost.png" },
        @{ Url = "$GitHubRepo/Icons/Source/EmptyRecycleBin.png"; Path = "Icons\Source\EmptyRecycleBin.png" },
        @{ Url = "$GitHubRepo/Icons/Source/GameTurbo.png"; Path = "Icons\Source\GameTurbo.png" },
        @{ Url = "$GitHubRepo/Icons/Source/GodMode.png"; Path = "Icons\Source\GodMode.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Hibernate.png"; Path = "Icons\Source\Hibernate.png" },
        @{ Url = "$GitHubRepo/Icons/Source/MaximizeWindow.png"; Path = "Icons\Source\MaximizeWindow.png" },
        @{ Url = "$GitHubRepo/Icons/Source/MinimizeWindow.png"; Path = "Icons\Source\MinimizeWindow.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Performance.png"; Path = "Icons\Source\Performance.png" },
        @{ Url = "$GitHubRepo/Icons/Source/PingCloudflare.png"; Path = "Icons\Source\PingCloudflare.png" },
        @{ Url = "$GitHubRepo/Icons/Source/PingGoogle.png"; Path = "Icons\Source\PingGoogle.png" },
        @{ Url = "$GitHubRepo/Icons/Source/PingTest.png"; Path = "Icons\Source\PingTest.png" },
        @{ Url = "$GitHubRepo/Icons/Source/PowerSaver.png"; Path = "Icons\Source\PowerSaver.png" },
        @{ Url = "$GitHubRepo/Icons/Source/PowerShell.png"; Path = "Icons\Source\PowerShell.png" },
        @{ Url = "$GitHubRepo/Icons/Source/ProcessKiller.png"; Path = "Icons\Source\ProcessKiller.png" },
        @{ Url = "$GitHubRepo/Icons/Source/ReduceMemory.png"; Path = "Icons\Source\ReduceMemory.png" },
        @{ Url = "$GitHubRepo/Icons/Source/RefreshDesktop.png"; Path = "Icons\Source\RefreshDesktop.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Restart.png"; Path = "Icons\Source\Restart.png" },
        @{ Url = "$GitHubRepo/Icons/Source/RoboCopy.png"; Path = "Icons\Source\RoboCopy.png" },
        @{ Url = "$GitHubRepo/Icons/Source/RoboPaste.png"; Path = "Icons\Source\RoboPaste.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Screensaver.png"; Path = "Icons\Source\Screensaver.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Shutdown.png"; Path = "Icons\Source\Shutdown.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Sleep.png"; Path = "Icons\Source\Sleep.png" },
        @{ Url = "$GitHubRepo/Icons/Source/SystemInfo.png"; Path = "Icons\Source\SystemInfo.png" },
        @{ Url = "$GitHubRepo/Icons/Source/TaskManager.png"; Path = "Icons\Source\TaskManager.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Transparency.png"; Path = "Icons\Source\Transparency.png" },
        @{ Url = "$GitHubRepo/Icons/Source/Volume.png"; Path = "Icons\Source\Volume.png" },
        @{ Url = "$GitHubRepo/Icons/Source/VolumeDown.png"; Path = "Icons\Source\VolumeDown.png" },
        @{ Url = "$GitHubRepo/Icons/Source/VolumeMax.png"; Path = "Icons\Source\VolumeMax.png" },
        @{ Url = "$GitHubRepo/Icons/Source/VolumeMute.png"; Path = "Icons\Source\VolumeMute.png" },
        @{ Url = "$GitHubRepo/Icons/Source/VolumeUp.png"; Path = "Icons\Source\VolumeUp.png" },
        @{ Url = "$GitHubRepo/Icons/Source/WifiToggle.png"; Path = "Icons\Source\WifiToggle.png" }
    )

    $iconCount = 0
    foreach ($icon in $iconPack) {
        $outputPath = Join-Path $codexPath $icon.Path
        if (Download-File -Url $icon.Url -OutputPath $outputPath -Description "Icon: $(Split-Path $icon.Path -Leaf)") {
            $iconCount++
        }
        else {
            # If an icon fails to download and we are processing icons, it's critical
            Write-Host "❌ Critical icon $($icon.Path) failed to download. Installation cannot continue as icons are being processed." -ForegroundColor Red
            exit 1
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
if (-not ($registryPath -and (Test-Path $registryPath -PathType Leaf))) { # Added -PathType Leaf and null check
    Write-Host "❌ ERROR: Registry file '$registryPath' not found or is not a file. Skipping registry path update." -ForegroundColor Red
    # If $Portable is false, this is a critical issue.
    if (-not $Portable) {
        Write-Host "❌ This is a critical error as registry installation is requested. Installation cannot proceed." -ForegroundColor Red
        exit 1
    }
}
else {
    $regContent = Get-Content $registryPath -Raw
    $regContent = $regContent -replace '%%CODEX_INSTALL_PATH%%', $codexPath.Replace('\', '\\')
    Set-Content -Path $registryPath -Value $regContent -Encoding UTF8
    Write-Host "✓ Registry paths updated in '$registryPath'" -ForegroundColor Green
}

# Install registry entries
if (-not $Portable) {
    Write-Host ""
    Write-Host "📝 Installing registry entries..." -ForegroundColor Yellow

    if (-not ($registryPath -and (Test-Path $registryPath -PathType Leaf))) { # Added -PathType Leaf and null check
        Write-Host "❌ ERROR: Registry file '$registryPath' not found or is not a file. Skipping registry import." -ForegroundColor Red
        Write-Host "   This is unexpected if downloads completed. Please check the 'Registry' folder in '$codexPath'." -ForegroundColor Yellow
        # This implies a critical failure if we reached here and $Portable is false.
        exit 1
    }
    else {
        try {
            Write-Host "  Importing registry file: $registryPath" -ForegroundColor Gray
            & regedit.exe /s $registryPath
            Write-Host "✓ Codex context menu installed!" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Registry installation failed. Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "   Run '$codexPath\Scripts\Install.ps1' manually as Administrator, or import '$registryPath' manually." -ForegroundColor Yellow
        }
    }
}

# Create desktop shortcuts and start menu entries
# Write-Host ""
# Write-Host "🔗 Creating shortcuts..." -ForegroundColor Cyan
# The section above regarding shortcuts might be reviewed later if actual shortcut creation is desired.
# For now, the primary focus is on the uninstaller path.

# Define the path for the uninstaller script downloaded via $coreFiles
$uninstallPath = Join-Path $codexPath (Join-Path 'Scripts' 'Uninstall-Codex.ps1')

if (Test-Path $uninstallPath) {
    Write-Host "✓ Comprehensive uninstaller is available at: $uninstallPath" -ForegroundColor Green
}
else {
    Write-Host "⚠️ WARNING: Comprehensive uninstaller was NOT found at $uninstallPath. This should not happen if critical downloads succeeded." -ForegroundColor Yellow
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
