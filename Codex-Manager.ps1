# Plexus Codex - Remote Installer/Uninstaller
# Usage: irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Codex-Manager.ps1 | iex

param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Force,
    [switch]$UserInstall,
    [switch]$KeepFiles,
    [string]$InstallPath
)

# GitHub repository configuration
$GitHubRepo = "https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Display header
Write-Host ""
Write-Host "██████╗ ██╗     ███████╗██╗  ██╗██╗   ██╗███████╗" -ForegroundColor Cyan
Write-Host "██╔══██╗██║     ██╔════╝╚██╗██╔╝██║   ██║██╔════╝" -ForegroundColor Cyan
Write-Host "██████╔╝██║     █████╗   ╚███╔╝ ██║   ██║███████╗" -ForegroundColor Cyan
Write-Host "██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██║   ██║╚════██║" -ForegroundColor Cyan
Write-Host "██║     ███████╗███████╗██╔╝ ██╗╚██████╔╝███████║" -ForegroundColor Cyan
Write-Host "╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "                    🎯 CODEX 🎯" -ForegroundColor White
Write-Host "        Advanced Windows Context Menu System" -ForegroundColor Gray
Write-Host ""

# Function to check if Codex is installed
function Test-CodexInstalled {
    $registryPaths = @(
        "HKCR:\Directory\Background\shell\Codex",
        "HKCU:\SOFTWARE\Classes\Directory\Background\shell\Codex",
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\Codex"
    )

    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}

# Function to find existing Codex installation
function Find-CodexInstallation {
    $commonPaths = @(
        "$env:ProgramData\Plexus\Codex",
        "$env:LOCALAPPDATA\Plexus\Codex"
        # User-specific paths like "$env:USERPROFILE\Plexus Codex\Codex" were removed
        # and "C:\Users\Marek\Plexus Codex\Codex" was removed
    )

    foreach ($path in $commonPaths) {
        if (Test-Path "$path\Scripts\Install-Codex.ps1") {
            return $path
        }
    }
    return $null
}

# Function to perform installation
function Install-Codex {
    param([string]$InstallPath, [bool]$UserInstall)

    Write-Host "🚀 Installing Plexus Codex..." -ForegroundColor Green
    Write-Host ""

    # Download and execute the main installer
    try {
        $installerUrl = "$GitHubRepo/Scripts/Install-Codex.ps1" # Changed to new installer
        Write-Host "Downloading installer from: $installerUrl" -ForegroundColor Gray

        $installerScript = Invoke-RestMethod -Uri $installerUrl -ErrorAction Stop
        # Prepare installer arguments
        $installerArgs = @{}
        $installerArgs['GitHubRepo'] = $GitHubRepo
        if ($InstallPath) { $installerArgs['InstallPath'] = $InstallPath }
        if ($UserInstall) { $installerArgs['UserInstall'] = $true }

        # Execute installer
        # Create a temporary script block and invoke with splatted parameters
        $scriptBlock = [scriptblock]::Create($installerScript)
        & $scriptBlock @installerArgs

        Write-Host ""
        Write-Host "✅ Codex installation completed!" -ForegroundColor Green
        Write-Host "Right-click on your desktop to access the Codex menu." -ForegroundColor Gray

    }
    catch {
        Write-Host "❌ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Function to perform uninstallation
function Uninstall-Codex {
    param([bool]$KeepFiles, [bool]$Force)

    Write-Host "🗑️ Uninstalling Plexus Codex..." -ForegroundColor Yellow
    Write-Host ""

    # Find existing installation
    $codexPath = Find-CodexInstallation

    if ($codexPath) {
        Write-Host "Found Codex installation at: $codexPath" -ForegroundColor Gray

        # Check if uninstaller exists
        $uninstallerPath = "$codexPath\Scripts\Uninstall-Codex.ps1"
        if (Test-Path $uninstallerPath) {
            Write-Host "Using local uninstaller..." -ForegroundColor Gray

            # Prepare uninstaller arguments
            $uninstallerArgs = @()
            if ($KeepFiles) { $uninstallerArgs += "-KeepFiles" }
            if ($Force) { $uninstallerArgs += "-Force" }
            $uninstallerArgs += "-Quiet"

            # Execute local uninstaller
            & $uninstallerPath @uninstallerArgs
        }
        else {
            Write-Host "Local uninstaller not found, using manual removal..." -ForegroundColor Yellow
            Uninstall-CodexManual -CodexPath $codexPath -KeepFiles $KeepFiles
        }
    }
    else {
        Write-Host "No local installation found, performing registry cleanup..." -ForegroundColor Yellow
        Uninstall-CodexManual -KeepFiles $KeepFiles
    }

    Write-Host ""
    Write-Host "✅ Codex uninstallation completed!" -ForegroundColor Green
}

# Function for manual uninstallation
function Uninstall-CodexManual {
    param([string]$CodexPath, [bool]$KeepFiles)

    # Remove registry entries
    $registryKeys = @(
        "HKCR:\Directory\Background\shell\Codex",
        "HKCU:\SOFTWARE\Classes\Directory\Background\shell\Codex",
        "HKLM:\SOFTWARE\Classes\Directory\Background\shell\Codex"
    )

    foreach ($key in $registryKeys) {
        try {
            if (Test-Path $key) {
                Remove-Item -Path $key -Recurse -Force -ErrorAction Stop
                Write-Host "✓ Removed registry key: $key" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "⚠ Could not remove: $key" -ForegroundColor Yellow
        }
    }

    # Restart Windows Explorer
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-Process explorer
        Write-Host "✓ Windows Explorer restarted" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ Please restart Windows Explorer manually" -ForegroundColor Yellow
    }

    # Remove files if requested
    if (-not $KeepFiles -and $CodexPath -and (Test-Path $CodexPath)) {
        try {
            Remove-Item -Path $CodexPath -Recurse -Force
            Write-Host "✓ Removed Codex files: $CodexPath" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠ Could not remove files: $CodexPath" -ForegroundColor Yellow
        }
    }
}

# Main logic
if ($Install -and $Uninstall) {
    Write-Host "❌ Cannot specify both -Install and -Uninstall" -ForegroundColor Red
    exit 1
}

# Check current installation status
$isInstalled = Test-CodexInstalled
$codexPath = Find-CodexInstallation

if ($Install) {
    if ($isInstalled -and -not $Force) {
        Write-Host "⚠️ Codex appears to be already installed." -ForegroundColor Yellow
        $choice = Read-Host "Do you want to reinstall? (y/N)"
        if ($choice.ToUpper() -ne "Y") {
            Write-Host "Installation cancelled." -ForegroundColor Gray
            exit 0
        }
    }
    Install-Codex -InstallPath $InstallPath -UserInstall $UserInstall
    exit 0
}

if ($Uninstall) {
    if (-not $isInstalled -and -not $Force) {
        Write-Host "⚠️ Codex does not appear to be installed." -ForegroundColor Yellow
        $choice = Read-Host "Do you want to perform cleanup anyway? (y/N)"
        if ($choice.ToUpper() -ne "Y") {
            Write-Host "Uninstallation cancelled." -ForegroundColor Gray
            exit 0
        }
    }
    Uninstall-Codex -KeepFiles $KeepFiles -Force $Force
    exit 0
}

# Interactive mode - no parameters specified
Write-Host "🔍 Current Status:" -ForegroundColor Cyan
if ($isInstalled) {
    Write-Host "   ✅ Codex is INSTALLED" -ForegroundColor Green
    if ($codexPath) {
        Write-Host "   📁 Location: $codexPath" -ForegroundColor Gray
    }
}
else {
    Write-Host "   ❌ Codex is NOT installed" -ForegroundColor Red
}

if (-not $isAdmin) {
    Write-Host "   ⚠️  Not running as Administrator" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 What would you like to do?" -ForegroundColor Cyan
Write-Host ""

if (-not $isInstalled) {
    Write-Host "1) Install Codex (System-wide)" -ForegroundColor Green
    Write-Host "2) Install Codex (User-only)" -ForegroundColor Green
    Write-Host "3) Exit" -ForegroundColor Gray
    Write-Host ""

    do {
        $choice = Read-Host "Select option (1-3)"
        switch ($choice) {
            "1" {
                if (-not $isAdmin) {
                    Write-Host "❌ Administrator privileges required for system-wide installation" -ForegroundColor Red
                    Write-Host "Please re-run PowerShell as Administrator or choose option 2" -ForegroundColor Yellow
                    continue
                }
                Install-Codex -UserInstall $false
                break
            }
            "2" {
                Install-Codex -UserInstall $true
                break
            }
            "3" {
                Write-Host "Goodbye! 👋" -ForegroundColor Gray
                exit 0
            }
            default {
                Write-Host "Invalid choice. Please select 1, 2, or 3." -ForegroundColor Red
            }
        }
    } while ($choice -notin @("1", "2", "3"))
}
else {
    Write-Host "1) Reinstall Codex" -ForegroundColor Blue
    Write-Host "2) Uninstall Codex (Remove everything)" -ForegroundColor Red
    Write-Host "3) Uninstall Codex (Keep files)" -ForegroundColor Yellow
    Write-Host "4) Exit" -ForegroundColor Gray
    Write-Host ""

    do {
        $choice = Read-Host "Select option (1-4)"
        switch ($choice) {
            "1" {
                Install-Codex -UserInstall (-not $isAdmin)
                break
            }
            "2" {
                Write-Host ""
                Write-Host "⚠️ This will completely remove Codex from your system." -ForegroundColor Red
                $confirm = Read-Host "Are you sure? (y/N)"
                if ($confirm.ToUpper() -eq "Y") {
                    Uninstall-Codex -KeepFiles $false -Force $false
                }
                else {
                    Write-Host "Uninstallation cancelled." -ForegroundColor Gray
                }
                break
            }
            "3" {
                Write-Host ""
                Write-Host "This will remove the context menu but keep Codex files." -ForegroundColor Yellow
                $confirm = Read-Host "Continue? (y/N)"
                if ($confirm.ToUpper() -eq "Y") {
                    Uninstall-Codex -KeepFiles $true -Force $false
                }
                else {
                    Write-Host "Uninstallation cancelled." -ForegroundColor Gray
                }
                break
            }
            "4" {
                Write-Host "Goodbye! 👋" -ForegroundColor Gray
                exit 0
            }
            default {
                Write-Host "Invalid choice. Please select 1, 2, 3, or 4." -ForegroundColor Red
            }
        }
    } while ($choice -notin @("1", "2", "3", "4"))
}

Write-Host ""
Write-Host "🎯 CODEX: Where functionality meets cyberpunk aesthetics!" -ForegroundColor Cyan
Write-Host "⭐ Star the repo: https://github.com/Marek-Codex/Plexus-Codex" -ForegroundColor Gray
