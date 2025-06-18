# Plexus Codex - Advanced Windows Context Menu System

## Overview
Plexus Codex is a comprehensive Windows context menu enhancement that provides quick access to system optimization tools, performance management, and utility functions.

## Features

### 🚀 Power Management
- **Power Saver**: Low power consumption mode
- **Balanced**: Standard Windows balanced mode
- **High Performance**: Maximum performance mode
- **GameTurbo**: Ultimate gaming optimization with:
  - CPU throttling disabled
  - Maximum CPU frequency
  - High priority for gaming processes
  - Disabled unnecessary services
  - Network optimization for gaming
  - Memory optimization
- **Dynamic Boost**: Intelligent performance management that:
  - Monitors CPU, Memory, and GPU usage
  - Detects running games automatically
  - Adjusts performance settings based on system load
  - Switches between power modes dynamically

### 🔧 System Tools
- **Task Manager**: Quick access to Windows Task Manager
- **Reduce Memory**: Aggressive memory cleanup and process optimization
- **God Mode**: Access to all Windows control panel settings
- **Cleanup Temporary Files**: Comprehensive system cleanup including:
  - Temp folders
  - Windows Update cache
  - Browser cache
  - Recent files
  - Prefetch files

### 🌐 Network Tools
- **Ping Test**: Network connectivity testing with:
  - Google (8.8.8.8)
  - Cloudflare (1.1.1.1)
  - Custom IP/hostname input

### 📁 File Operations
- **RoboCopy**: Advanced file copying with multi-threading
- **RoboPaste**: Smart paste operation using previously copied files

## Installation

### 🚀 One-Line Install (Recommended)
Install directly from GitHub using PowerShell (Run as Administrator):

```powershell
# Interactive installer/uninstaller
irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Codex-Manager.ps1 | iex

# Direct install
irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Codex-Manager.ps1 | iex -Install

# Direct uninstall
irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Codex-Manager.ps1 | iex -Uninstall
```

### 📥 Alternative: Download Batch File
For users who prefer a GUI experience:
1. Download [`Codex-Manager.bat`](Codex-Manager.bat)
2. Right-click and "Run as Administrator"
3. Follow the on-screen prompts

### 🛠️ Manual Installation
If you prefer manual installation:

1. **Download this repository**
2. **Run as Administrator**: Right-click PowerShell and select "Run as Administrator"
3. **Navigate to the Codex folder**
4. **Run the installation script**:
   ```powershell
   .\Install.ps1
   ```

1. **Import Registry**: Right-click `Registry\Codex.reg` and select "Merge"
2. **Set Execution Policy**:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## Usage

After installation, right-click on the desktop or in any folder to access the Codex menu.

### GameTurbo Features
When activated, GameTurbo will:
- Switch to High Performance power plan
- Disable CPU throttling
- Set CPU minimum and maximum states to 100%
- Stop unnecessary Windows services
- Set high priority for gaming processes
- Optimize network settings for gaming
- Clear system memory
- Disable Windows Game Mode interference

### Dynamic Boost Intelligence
Dynamic Boost analyzes your system every 10 seconds and:
- Detects running games automatically
- Monitors CPU, Memory, and GPU usage
- Switches to Gaming mode when games are detected with high load
- Uses High Performance for intensive non-gaming tasks
- Falls back to Balanced for normal operation
- Switches to Power Saver when on battery with low load

## File Structure
```
GhostMode/
├── Scripts/
│   ├── PowerManager.ps1      # Standard power plan switching
│   ├── GameTurbo.ps1         # Ultimate gaming optimization
│   ├── DynamicBoost.ps1      # Intelligent performance management
│   ├── PingTest.ps1          # Network connectivity testing
│   ├── ReduceMemory.ps1      # Memory optimization
│   ├── CleanupTemp.ps1       # System cleanup
│   ├── RoboCopy.ps1          # Advanced file copying
│   └── RoboPaste.ps1         # Smart paste operations
├── Registry/
│   └── GhostMode.reg         # Registry entries for context menu
├── Install.ps1               # Installation script
└── README.md                 # This file
```

## Requirements
- Windows 10/11
- PowerShell 5.0 or later
- Administrator privileges for installation
- Administrator privileges for some features (GameTurbo, system cleanup)

## Uninstallation

### Automatic Uninstallation (Recommended)
Run the uninstaller script as Administrator:
```powershell
# Navigate to Codex directory
cd "C:\Users\Marek\Plexus Codex\Codex\Scripts"

# Run uninstaller
.\Uninstall-Codex.ps1
```

**Uninstaller Options:**
- `.\Uninstall-Codex.ps1` - Interactive uninstall with prompts
- `.\Uninstall-Codex.ps1 -Force` - Automatic uninstall (no prompts)
- `.\Uninstall-Codex.ps1 -KeepFiles` - Remove registry only, keep files
- `.\Uninstall-Codex.ps1 -Quiet` - Silent uninstall (no output)

### Manual Uninstallation
If the automatic uninstaller fails:
1. Open Registry Editor (regedit) as Administrator
2. Navigate to `HKEY_CLASSES_ROOT\Directory\Background\shell\`
3. Delete the `Codex` key
4. Restart Windows Explorer or reboot
5. Optionally delete the Codex folder

## Notes
- Some features require Administrator privileges
- GameTurbo may temporarily disable certain Windows services
- Dynamic Boost runs continuous monitoring when activated
- RoboCopy operations are stored temporarily for RoboPaste functionality

## Troubleshooting

**Scripts not running**: Check execution policy with `Get-ExecutionPolicy`
**No context menu**: Ensure registry was imported as Administrator
**GameTurbo not working**: Run PowerShell as Administrator
**Dynamic Boost issues**: Check if games are properly detected in the process list

## Advanced Usage

### Running Dynamic Boost in Monitor Mode
For continuous system monitoring:
```powershell
.\Scripts\DynamicBoost.ps1 -Monitor
```

This will run Dynamic Boost in a continuous monitoring mode that analyzes and adjusts performance every 10 seconds.

---
**Codex** - Supercharge your Windows experience! 👻
