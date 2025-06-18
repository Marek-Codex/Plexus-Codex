# Codex Installation Locations Guide

## 🎯 **Recommended Installation Paths**

### **System-Wide Installation (Preferred)**
```
C:\ProgramData\Plexus\Codex\
```
**Benefits:**
✅ Available to all users on the system  
✅ Survives user profile changes  
✅ Professional installation location  
✅ Follows Windows best practices  
✅ Better for corporate/shared environments  

**Requirements:** Administrator privileges

---

### **User-Specific Installation**
```
C:\Users\[Username]\AppData\Local\Plexus\Codex\
```
**Benefits:**
✅ No admin privileges required  
✅ User-specific customization  
✅ Portable across user sessions  
✅ Easy to backup with user data  

**Requirements:** Standard user privileges

---

### **Portable Installation**
```
[Any Location]\Codex\
```
**Benefits:**
✅ Can be on USB drives  
✅ No registry modifications  
✅ Easy to move/copy  
✅ Perfect for testing  

**Requirements:** Manual registry import when needed

---

## 📁 **Windows Standard Directories**

### **ProgramData** (Recommended for System Tools)
- **Path:** `C:\ProgramData\`
- **Purpose:** Application data shared by all users
- **Permissions:** Admin to write, all users to read
- **Best for:** System utilities, shared tools, context menus

### **Program Files**
- **Path:** `C:\Program Files\` or `C:\Program Files (x86)\`
- **Purpose:** Application executables and core files
- **Permissions:** Admin required, highly protected
- **Best for:** Traditional installed applications

### **LocalAppData**
- **Path:** `C:\Users\[User]\AppData\Local\`
- **Purpose:** User-specific application data
- **Permissions:** User-specific access
- **Best for:** User customizations, personal tools

### **RoamingAppData**
- **Path:** `C:\Users\[User]\AppData\Roaming\`
- **Purpose:** User settings that follow across machines
- **Permissions:** User-specific, syncs in domain environments
- **Best for:** Settings, configurations

---

## 🔧 **Installation Options for Codex**

### **Option 1: System Administrator (Recommended)**
```powershell
# Full system installation with admin privileges
irm codex.link/install | iex

# Installs to: C:\ProgramData\Plexus\Codex\
# Registry: HKEY_LOCAL_MACHINE (all users)
```

### **Option 2: Current User Only**
```powershell
# User-specific installation
irm codex.link/install | iex -UserInstall

# Installs to: C:\Users\[User]\AppData\Local\Plexus\Codex\
# Registry: HKEY_CURRENT_USER (current user only)
```

### **Option 3: Custom Location**
```powershell
# Install to specific path
irm codex.link/install | iex -InstallPath "C:\Tools\Codex"

# Custom installation path
# Registry: Uses specified path
```

### **Option 4: Portable Mode**
```powershell
# No registry changes, manual setup
irm codex.link/install | iex -Portable

# Can be installed anywhere
# Manual registry import required
```

---

## 🏢 **Corporate Environment Considerations**

### **Domain Environments:**
- Use `C:\ProgramData\` for system-wide deployment
- Group Policy can deploy via logon scripts
- Registry entries in HKEY_LOCAL_MACHINE
- Permissions managed by IT administrators

### **Shared Computers:**
- System-wide installation benefits all users
- Consistent experience across user sessions
- Centralized management and updates
- Better security with admin-controlled installation

### **BYOD/Personal Devices:**
- User-specific installation for personal customization
- No admin privileges required
- User can customize and modify freely
- Doesn't affect other users

---

## 🔒 **Security & Permissions**

### **ProgramData Security:**
```
C:\ProgramData\Plexus\Codex\
├── Scripts\           # Admin: Full, Users: Read+Execute
├── Registry\          # Admin: Full, Users: Read
├── Tools\             # Admin: Full, Users: Read+Execute
├── Icons\             # Admin: Full, Users: Read
└── Logs\              # Admin: Full, Users: Read+Write
```

### **Registry Security:**
```
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Directory\Background\shell\GhostMode
- Admin required to create/modify
- All users can execute context menu items
- Better security than HKEY_CURRENT_USER for system tools
```

---

## 📦 **Deployment Strategies**

### **Small Business/Home:**
```powershell
# Simple system-wide installation
irm codex.link/install | iex
```

### **Enterprise Deployment:**
```powershell
# Scripted deployment with logging
irm codex.link/enterprise | iex -LogPath "\\server\logs\"
```

### **Developer Environments:**
```powershell
# Development installation with source control
irm codex.link/dev | iex -InstallPath "C:\Dev\Tools\Codex"
```

---

## 🛠️ **Uninstallation & Cleanup**

### **System Installation:**
- Remove: `C:\ProgramData\Plexus\Codex\`
- Registry: `HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Directory\Background\shell\GhostMode`
- Requires: Administrator privileges

### **User Installation:**
- Remove: `C:\Users\[User]\AppData\Local\Plexus\Codex\`
- Registry: `HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\GhostMode`
- Requires: User privileges only

---

## 🎯 **Best Practices Summary**

1. **Use ProgramData for system tools** like Codex
2. **Require admin privileges** for proper installation
3. **Provide fallback options** for non-admin scenarios
4. **Follow Windows conventions** for professional appearance
5. **Consider corporate environments** in design decisions
6. **Provide clean uninstallation** options

The `C:\ProgramData\Plexus\Codex\` location is perfect for Codex because:
- It's designed for exactly this type of system utility
- It provides the right balance of accessibility and security
- It follows Microsoft's recommendations for context menu tools
- It ensures consistent experience across all users
