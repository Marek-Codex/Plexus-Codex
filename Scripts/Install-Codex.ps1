# Codex One-Click Installer - Downloads and installs the complete Codex system
# Usage: irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Install-Codex.ps1 | iex

param(
    [string]$InstallPath,
    [switch]$NoIcons,
    [switch]$Portable,
    [switch]$UserInstall,
    [string]$GitHubRepo = "https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main"
)

# Start transcript for install debugging
Start-Transcript -Path "$env:TEMP\Plexus-Codex-Install.log" -Append -ErrorAction SilentlyContinue

# Ensure errors stop and are caught by trap
$ErrorActionPreference = 'Stop'
trap {
    Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor Red
    Read-Host "Press Enter to exit"
    Stop-Transcript -ErrorAction SilentlyContinue
    exit 1
}

# Ensure GitHubRepo
if (-not $GitHubRepo) { Write-Error "GitHubRepo must be provided"; exit 1 }

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Title
Write-Host "=== Plexus Codex One-Click Installer ===" -ForegroundColor Cyan
Write-Host "🎯 The ultimate Windows context menu system" -ForegroundColor White
Write-Host ""

# Compute installation base path and final 'Codex' directory
if ($InstallPath) {
    # Custom base provided
    $basePath = $InstallPath.TrimEnd('\\')
}
elseif ($UserInstall -or -not $isAdmin) {
    # User-only installation
    $basePath = "$env:LOCALAPPDATA\Plexus"
}
else {
    # System-wide installation
    $basePath = "$env:ProgramData\Plexus"
}
$codexPath = Join-Path $basePath 'Codex'
Write-Host "📁 Installing to: $codexPath" -ForegroundColor Cyan

# Create installation directory
Write-Host "📁 Creating installation directory..." -ForegroundColor Green
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
                Read-Host "Critical download of $($Description) failed. $($_.Exception.Message). Press Enter to exit"
                return $false
            }
        }
    }
    return $false # Should not be reached if logic is correct
}

# Core files to download
$coreFiles = @(
    @{ Url = "$GitHubRepo/Registry/Codex.reg"; Path = "Registry\Codex.reg"; Name = "Registry Structure" }
    @{ Url = "$GitHubRepo/Scripts/Uninstall-Codex.ps1"; Path = "Scripts\Uninstall-Codex.ps1"; Name = "Comprehensive Uninstaller" }
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
            "Icon Tinter", "NirCmd Utility"
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
if (Test-Path $registryPath) {
    # Read and replace placeholder
    $regContent = Get-Content $registryPath -Raw
    $escapedPath = $codexPath.Replace('\\', '\\\\')
    $regContent = $regContent -replace '%%CODEX_INSTALL_PATH%%', $escapedPath
    # Debug: show first few lines to confirm
    Write-Host "DEBUG: First lines of processed registry content:" -ForegroundColor Magenta
    $regContent.Split("`n")[0..10] | ForEach-Object { Write-Host $_ -ForegroundColor Magenta }

    # Write back
    Set-Content -Path $registryPath -Value $regContent -Encoding UTF8
    Write-Host "✓ Registry paths updated" -ForegroundColor Green

    # Verify tinted icon exists
    $brandIcon = Join-Path $codexPath "Icons\Tinted\BrandIcon.ico"
    if (-not (Test-Path $brandIcon)) {
        Write-Host "WARNING: BrandIcon.ico not found at $brandIcon" -ForegroundColor Yellow
    }
    else {
        Write-Host "DEBUG: BrandIcon found at $brandIcon" -ForegroundColor Magenta
    }
}
else {
    Write-Host "ERROR: Registry template not found at $registryPath" -ForegroundColor Red
}

# Install registry entries
if (-not $Portable) {
    Write-Host ""
    Write-Host "📝 Installing registry entries..." -ForegroundColor Yellow
    Write-Host "DEBUG: registryPath = '$registryPath'" -ForegroundColor Magenta
    if (-not (Test-Path $registryPath)) {
        Write-Host "ERROR: Reg file not found at path: $registryPath" -ForegroundColor Red
    }
    else {
        Write-Host "DEBUG: Running: regedit.exe /s $registryPath" -ForegroundColor Magenta
        try {
            $proc = Start-Process -FilePath regedit.exe -ArgumentList "/s", $registryPath -Wait -PassThru -ErrorAction Stop
            Write-Host "DEBUG: regedit exit code = $($proc.ExitCode)" -ForegroundColor Magenta
            if ($proc.ExitCode -eq 0) {
                Write-Host "✓ Codex context menu installed!" -ForegroundColor Green
            }
            else {
                Write-Host "ERROR: regedit returned exit code $($proc.ExitCode)" -ForegroundColor Red
                Write-Host "⚠️  Registry installation may have failed. Run Install.ps1 manually as Administrator." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
        }
        catch {
            Write-Host "⚠️  Exception running regedit: $($_.Exception.Message)" -ForegroundColor Red
            Read-Host "Press Enter to continue"
        }
    }
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
Write-Host "• Uninstall: $($codexPath)\Scripts\Uninstall-Codex.ps1" -ForegroundColor Gray
Write-Host "• Reconfigure: $codexPath\Scripts\Install.ps1" -ForegroundColor Gray
Write-Host "• Icon Reference: $codexPath\ICONS.md" -ForegroundColor Gray

Write-Host ""
Write-Host "🎯 CODEX: Where functionality meets cyberpunk aesthetics!" -ForegroundColor Cyan

# Stop transcript
Stop-Transcript -ErrorAction SilentlyContinue
