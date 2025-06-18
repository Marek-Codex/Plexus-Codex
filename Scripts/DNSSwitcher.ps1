# DNS Switcher - Quick DNS server switching with cyberpunk flair
param([string]$DNSProfile)

# DNS profiles for quick switching
$DNSProfiles = @{
    "Google" = @{
        Primary = "8.8.8.8"
        Secondary = "8.8.4.4"
        Name = "Google DNS"
        Description = "Fast, reliable public DNS"
    }
    "Cloudflare" = @{
        Primary = "1.1.1.1"
        Secondary = "1.0.0.1"
        Name = "Cloudflare DNS"
        Description = "Privacy-focused, ultra-fast DNS"
    }
    "Quad9" = @{
        Primary = "9.9.9.9"
        Secondary = "149.112.112.112"
        Name = "Quad9 DNS"
        Description = "Security-focused DNS with malware blocking"
    }
    "OpenDNS" = @{
        Primary = "208.67.222.222"
        Secondary = "208.67.220.220"
        Name = "OpenDNS"
        Description = "Content filtering and security"
    }
    "Auto" = @{
        Primary = "DHCP"
        Secondary = "DHCP"
        Name = "Automatic (DHCP)"
        Description = "Use router/ISP provided DNS"
    }
}

function Show-DNSMenu {
    Write-Host "=== Codex DNS Switcher ===" -ForegroundColor Cyan
    Write-Host "Select DNS profile:" -ForegroundColor White
    Write-Host ""
    
    $i = 1
    foreach ($profile in $DNSProfiles.Keys) {
        $info = $DNSProfiles[$profile]
        Write-Host "[$i] $($info.Name)" -ForegroundColor Green
        Write-Host "    Primary: $($info.Primary)" -ForegroundColor Gray
        Write-Host "    Secondary: $($info.Secondary)" -ForegroundColor Gray
        Write-Host "    $($info.Description)" -ForegroundColor Yellow
        Write-Host ""
        $i++
    }
    
    Write-Host "[F] Flush DNS Cache" -ForegroundColor Magenta
    Write-Host "[C] Custom DNS Input" -ForegroundColor Cyan
    Write-Host "[S] Show Current DNS" -ForegroundColor Yellow
    Write-Host "[Q] Quit" -ForegroundColor Red
    Write-Host ""
}

function Get-ActiveNetworkAdapter {
    # Get the active network adapter (with internet connectivity)
    $adapter = Get-NetAdapter | Where-Object { 
        $_.Status -eq "Up" -and 
        $_.InterfaceDescription -notlike "*Virtual*" -and 
        $_.InterfaceDescription -notlike "*Loopback*"
    } | Select-Object -First 1
    
    return $adapter
}

function Set-DNSServers {
    param([string]$Primary, [string]$Secondary, [string]$ProfileName)
    
    try {
        $adapter = Get-ActiveNetworkAdapter
        if (-not $adapter) {
            Write-Host "✗ No active network adapter found!" -ForegroundColor Red
            return $false
        }
        
        Write-Host "Setting DNS on adapter: $($adapter.Name)" -ForegroundColor Cyan
        
        if ($Primary -eq "DHCP") {
            # Set to automatic (DHCP)
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
            Write-Host "✓ DNS set to Automatic (DHCP)" -ForegroundColor Green
        } else {
            # Set custom DNS servers
            if ($Secondary) {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $Primary, $Secondary
            } else {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $Primary
            }
            Write-Host "✓ DNS changed to $ProfileName" -ForegroundColor Green
            Write-Host "  Primary: $Primary" -ForegroundColor Gray
            if ($Secondary) {
                Write-Host "  Secondary: $Secondary" -ForegroundColor Gray
            }
        }
        
        # Flush DNS cache
        Clear-DnsClientCache
        Write-Host "✓ DNS cache flushed" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "✗ Error setting DNS: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-CurrentDNS {
    try {
        $adapter = Get-ActiveNetworkAdapter
        if (-not $adapter) {
            Write-Host "✗ No active network adapter found!" -ForegroundColor Red
            return
        }
        
        $dnsServers = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4
        
        Write-Host "=== Current DNS Configuration ===" -ForegroundColor Cyan
        Write-Host "Adapter: $($adapter.Name)" -ForegroundColor White
        
        if ($dnsServers.ServerAddresses.Count -eq 0) {
            Write-Host "DNS: Automatic (DHCP)" -ForegroundColor Yellow
        } else {
            Write-Host "DNS Servers:" -ForegroundColor White
            for ($i = 0; $i -lt $dnsServers.ServerAddresses.Count; $i++) {
                $server = $dnsServers.ServerAddresses[$i]
                $label = if ($i -eq 0) { "Primary" } else { "Secondary" }
                Write-Host "  $label`: $server" -ForegroundColor Green
            }
        }
        Write-Host ""
    }
    catch {
        Write-Host "✗ Error getting DNS info: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-CustomDNS {
    Write-Host "=== Custom DNS Setup ===" -ForegroundColor Cyan
    
    $primary = Read-Host "Enter Primary DNS server (e.g., 8.8.8.8)"
    if (-not $primary) {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }
    
    $secondary = Read-Host "Enter Secondary DNS server (optional, press Enter to skip)"
    
    Write-Host "Setting custom DNS..." -ForegroundColor Cyan
    if (Set-DNSServers -Primary $primary -Secondary $secondary -ProfileName "Custom DNS") {
        Write-Host "✓ Custom DNS applied successfully!" -ForegroundColor Green
    }
}

function Flush-DNSCache {
    try {
        Clear-DnsClientCache
        Write-Host "✓ DNS cache flushed successfully!" -ForegroundColor Green
        
        # Also flush system DNS resolver cache using NirCmd if available
        $nircmdPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Tools\nircmd.exe"
        if (Test-Path $nircmdPath) {
            & $nircmdPath flushdns
            Write-Host "✓ System DNS cache also flushed with NirCmd" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "✗ Error flushing DNS cache: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
if ($DNSProfile) {
    # Direct profile switching (for context menu)
    if ($DNSProfiles.ContainsKey($DNSProfile)) {
        $profile = $DNSProfiles[$DNSProfile]
        Write-Host "=== Codex DNS Switcher ===" -ForegroundColor Cyan
        Write-Host "Switching to $($profile.Name)..." -ForegroundColor White
        
        if (Set-DNSServers -Primary $profile.Primary -Secondary $profile.Secondary -ProfileName $profile.Name) {
            # Show notification
            Add-Type -AssemblyName System.Windows.Forms
            $notify = New-Object System.Windows.Forms.NotifyIcon
            $notify.Icon = [System.Drawing.SystemIcons]::Information
            $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
            $notify.BalloonTipText = "DNS switched to $($profile.Name)"
            $notify.BalloonTipTitle = "Codex - DNS Switcher"
            $notify.Visible = $true
            $notify.ShowBalloonTip(3000)
            
            Start-Sleep 2
            $notify.Dispose()
        }
    } else {
        Write-Host "✗ Unknown DNS profile: $DNSProfile" -ForegroundColor Red
        Write-Host "Available profiles: $($DNSProfiles.Keys -join ', ')" -ForegroundColor Yellow
    }
} else {
    # Interactive menu mode
    do {
        Show-DNSMenu
        $choice = Read-Host "Enter your choice"
        
        switch ($choice.ToUpper()) {
            "1" { Set-DNSServers -Primary $DNSProfiles["Google"].Primary -Secondary $DNSProfiles["Google"].Secondary -ProfileName $DNSProfiles["Google"].Name }
            "2" { Set-DNSServers -Primary $DNSProfiles["Cloudflare"].Primary -Secondary $DNSProfiles["Cloudflare"].Secondary -ProfileName $DNSProfiles["Cloudflare"].Name }
            "3" { Set-DNSServers -Primary $DNSProfiles["Quad9"].Primary -Secondary $DNSProfiles["Quad9"].Secondary -ProfileName $DNSProfiles["Quad9"].Name }
            "4" { Set-DNSServers -Primary $DNSProfiles["OpenDNS"].Primary -Secondary $DNSProfiles["OpenDNS"].Secondary -ProfileName $DNSProfiles["OpenDNS"].Name }
            "5" { Set-DNSServers -Primary $DNSProfiles["Auto"].Primary -Secondary $DNSProfiles["Auto"].Secondary -ProfileName $DNSProfiles["Auto"].Name }
            "F" { Flush-DNSCache }
            "C" { Set-CustomDNS }
            "S" { Get-CurrentDNS }
            "Q" { 
                Write-Host "Exiting DNS Switcher..." -ForegroundColor Yellow
                break 
            }
            default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red }
        }
        
        if ($choice.ToUpper() -ne "Q" -and $choice.ToUpper() -ne "S") {
            Write-Host ""
            Write-Host "Press any key to continue..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Clear-Host
        }
    } while ($choice.ToUpper() -ne "Q")
}
