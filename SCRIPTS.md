# Codex Scripts Reference

## Installation & Management

### `Install-Codex.ps1` (Main Installer)
Installs the complete Codex context menu system.

**Usage:**
```powershell
# Standard installation (requires Administrator)
.\Install-Codex.ps1

# User-only installation
.\Install-Codex.ps1 -UserInstall

# Portable mode (no registry changes)
.\Install-Codex.ps1 -Portable

# Skip icon processing
.\Install-Codex.ps1 -NoIcons
```

### `Uninstall-Codex.ps1` (Uninstaller)
Safely removes Codex from your system.

**Usage:**
```powershell
# Interactive uninstall
.\Uninstall-Codex.ps1

# Automatic uninstall (no prompts)
.\Uninstall-Codex.ps1 -Force

# Remove registry only, keep files
.\Uninstall-Codex.ps1 -KeepFiles

# Silent uninstall
.\Uninstall-Codex.ps1 -Quiet

# Combined options
.\Uninstall-Codex.ps1 -Force -KeepFiles -Quiet
```

## Icon & Branding

### `IconTinter.ps1` (Icon Processor)
Converts white PNG icons to brand-colored versions.

**Usage:**
```powershell
# Process all icons
.\IconTinter.ps1

# Force regeneration of existing icons
.\IconTinter.ps1 -Force

# Process specific icon
.\IconTinter.ps1 -IconName "BrandIcon"
```

### `ProcessBrandIcon.ps1` (Brand Icon Processor)
Crops, squares, resizes, and whitens the brand icon.

**Usage:**
```powershell
# Standard processing (100x100 pixels)
.\ProcessBrandIcon.ps1

# Custom input/output
.\ProcessBrandIcon.ps1 -InputIcon "MyIcon.png" -OutputIcon "ProcessedIcon.png"

# Custom size
.\ProcessBrandIcon.ps1 -TargetSize 64
```

### `CreateIconPlaceholders.ps1` (Icon Generator)
Creates placeholder icon files for missing icons.

**Usage:**
```powershell
# Create all missing placeholder icons
.\CreateIconPlaceholders.ps1
```

## System Functions

### `PowerManager.ps1` (Power Management)
Controls Windows power plans and performance settings.

**Modes:**
- `PowerSaver` - Low power consumption
- `Balanced` - Standard balanced mode  
- `Performance` - Maximum performance
- `GameTurbo` - Ultimate gaming optimization
- `DynamicBoost` - Intelligent performance management

### `CleanupTemp.ps1` (System Cleanup)
Comprehensive temporary file cleanup.

### `ReduceMemory.ps1` (Memory Optimization)
Aggressive memory cleanup and process optimization.

### `ProcessKiller.ps1` (Process Management)
Intelligent process termination with safeguards.

### `DNSSwitcher.ps1` (DNS Management)
Quick DNS server switching (Cloudflare, Google, ISP).

### `WifiToggle.ps1` (WiFi Control)
Toggle WiFi adapter on/off.

### `PingTest.ps1` (Network Testing)
Network connectivity testing tools.

### `RoboCopy.ps1` (File Operations)
Advanced file copying with RoboCopy.

### `RoboPaste.ps1` (File Pasting)
Paste files copied with RoboCopy.

## Utility Scripts

### `AutoIconMapper.ps1` (Icon Management)
Automatically maps icons to registry entries.

### `IconPaths.ps1` (Path Configuration)
Centralized icon path management.

### `NirCmdExplorer.ps1` (NirCmd Integration)
Windows Explorer integration for NirCmd tools.

### `CodexSummary.ps1` (System Info)
Displays comprehensive system information.

### `Create-StandaloneInstaller.ps1` (Packaging)
Creates standalone installer packages.

---

## Quick Start

1. **Install Codex:**
   ```powershell
   .\Install-Codex.ps1
   ```

2. **Process Icons:**
   ```powershell
   .\IconTinter.ps1
   ```

3. **Test Installation:**
   Right-click on desktop → "Codex" menu should appear

4. **Uninstall (if needed):**
   ```powershell
   .\Uninstall-Codex.ps1
   ```

## Notes

- Most scripts require **Administrator privileges**
- Scripts are designed to be **safe** and **reversible**
- Icon processing is **automatic** during installation
- All registry changes are **cleanly removable**
- Scripts include **comprehensive error handling**
