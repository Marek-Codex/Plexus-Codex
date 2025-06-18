# Codex Uninstaller - Removes Codex context menu system
# Safely removes all registry entries and optionally cleans up files

param(
    [switch]$KeepFiles,
    [switch]$Force,
    [switch]$Quiet
)

# Require Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: Administrator privileges required for uninstallation." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

$codexPath = "PLACEHOLDER_PATH"
$registryKeys = @(
    "HKEY_CLASSES_ROOT\Directory\Background\shell\Codex"
)

if (-not $Quiet) {
    Write-Host "=== Codex Uninstaller ===" -ForegroundColor Cyan
    Write-Host "This will remove the Codex context menu system from Windows." -ForegroundColor White
    Write-Host ""
    
    if (-not $Force) {
        $confirm = Read-Host "Are you sure you want to uninstall Codex? (y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Uninstallation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "Uninstalling Codex..." -ForegroundColor Yellow
}

$errors = @()
$success = $true

# Remove registry entries
Write-Host "Removing registry entries..." -ForegroundColor Gray

foreach ($key in $registryKeys) {
    try {
        $keyPath = $key -replace "HKEY_CLASSES_ROOT", "HKCR:"
        
        if (Test-Path $keyPath) {
            Remove-Item -Path $keyPath -Recurse -Force -ErrorAction Stop
            if (-not $Quiet) {
                Write-Host "✓ Removed: $key" -ForegroundColor Green
            }
        } else {
            if (-not $Quiet) {
                Write-Host "⚠ Not found: $key" -ForegroundColor Yellow
            }
        }
    } catch {
        $errors += "Failed to remove registry key: $key - $($_.Exception.Message)"
        $success = $false
        if (-not $Quiet) {
            Write-Host "✗ Failed: $key" -ForegroundColor Red
        }
    }
}

# Refresh Windows Explorer to apply changes
try {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer
    if (-not $Quiet) {
        Write-Host "✓ Windows Explorer restarted" -ForegroundColor Green
    }
} catch {
    if (-not $Quiet) {
        Write-Host "⚠ Could not restart Explorer automatically" -ForegroundColor Yellow
        Write-Host "  You may need to restart Explorer manually or reboot" -ForegroundColor Gray
    }
}

# Optional file cleanup
if (-not $KeepFiles) {
    Write-Host ""
    if (-not $Force -and -not $Quiet) {
        $removeFiles = Read-Host "Do you want to remove Codex files from disk? (y/N)"
    } else {
        $removeFiles = "y"
    }
    
    if ($removeFiles -match '^[Yy]') {
        Write-Host "Removing Codex files..." -ForegroundColor Gray
        
        try {
            if (Test-Path $codexPath) {
                Remove-Item -Path $codexPath -Recurse -Force -ErrorAction Stop
                if (-not $Quiet) {
                    Write-Host "✓ Removed Codex directory: $codexPath" -ForegroundColor Green
                }
            } else {
                if (-not $Quiet) {
                    Write-Host "⚠ Codex directory not found: $codexPath" -ForegroundColor Yellow
                }
            }
        } catch {
            $errors += "Failed to remove Codex directory: $($_.Exception.Message)"
            $success = $false
            if (-not $Quiet) {
                Write-Host "✗ Failed to remove files: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        if (-not $Quiet) {
            Write-Host "✓ Keeping Codex files on disk" -ForegroundColor Blue
        }
    }
}

# Final results
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Uninstallation Complete ===" -ForegroundColor Cyan
    
    if ($success) {
        Write-Host "✓ Codex has been successfully uninstalled!" -ForegroundColor Green
        Write-Host "The context menu entries have been removed." -ForegroundColor Gray
        
        if ($KeepFiles -or ($removeFiles -notmatch '^[Yy]')) {
            Write-Host ""
            Write-Host "Note: Codex files remain at: $codexPath" -ForegroundColor Blue
            Write-Host "You can manually delete this folder if desired." -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠ Uninstallation completed with some errors:" -ForegroundColor Yellow
        foreach ($error in $errors) {
            Write-Host "  • $error" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Changes will take effect after:" -ForegroundColor Gray
    Write-Host "• Restarting Windows Explorer (done automatically)" -ForegroundColor Gray
    Write-Host "• Or rebooting your computer" -ForegroundColor Gray
}

# Return appropriate exit code
if ($success) {
    exit 0
} else {
    exit 1
}
