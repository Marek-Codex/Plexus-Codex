# Wi-Fi Toggle Script
# Check current Wi-Fi status and toggle

$wifiAdapters = Get-NetAdapter | Where-Object { $_.Name -like "*Wi-Fi*" -or $_.Name -like "*Wireless*" -or $_.InterfaceDescription -like "*Wireless*" }

if ($wifiAdapters) {
    foreach ($adapter in $wifiAdapters) {
        if ($adapter.Status -eq "Up") {
            # Wi-Fi is on, turn it off
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
            $status = "disabled"
        } else {
            # Wi-Fi is off, turn it on
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false
            $status = "enabled"
        }
    }
    
    # Show notification
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notify.BalloonTipText = "Wi-Fi has been $status"
    $notify.BalloonTipTitle = "Codex - Wi-Fi Toggle"
    $notify.Visible = $true
    $notify.ShowBalloonTip(2000)
} else {
    # No Wi-Fi adapter found
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("No Wi-Fi adapter found.", "Codex - Wi-Fi Toggle", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}
