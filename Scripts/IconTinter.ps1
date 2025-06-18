# Icon Tinter - Creates brand-colored icons from white PNG sources
param([switch]$Force)

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Brand Colors
$brandPrimary = [System.Drawing.Color]::FromArgb(255, 60, 160, 255)    # #3CA0FF
$brandAccent = [System.Drawing.Color]::FromArgb(255, 160, 60, 255)     # #A03CFF

# Get Windows theme mode (light/dark) 
function Get-WindowsThemeMode {
    try {
        $themeValue = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
        
        if ($themeValue -eq 0) {
            return "Dark"
        } else {
            return "Light"
        }
    } catch {
        Write-Host "Could not detect theme mode, assuming Light" -ForegroundColor Yellow
        return "Light"
    }
}

# Function to tint a white PNG to accent color while preserving transparency
function Convert-WhitePngToTintedIcon {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [System.Drawing.Color]$TintColor,
        [float]$SaturationLevel = 1.0
    )
    
    try {
        # Load the source image
        $sourceImage = [System.Drawing.Image]::FromFile($SourcePath)
        $bitmap = New-Object System.Drawing.Bitmap($sourceImage.Width, $sourceImage.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        
        # Create graphics object
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([System.Drawing.Color]::Transparent)
        
        # Adjust tint color based on saturation level
        $adjustedTintColor = $TintColor
        if ($SaturationLevel -lt 1.0) {
            # Blend the accent color with grey based on saturation level
            $grey = [System.Drawing.Color]::FromArgb(255, 128, 128, 128)
            
            $red = [Math]::Round($grey.R + (($TintColor.R - $grey.R) * $SaturationLevel))
            $green = [Math]::Round($grey.G + (($TintColor.G - $grey.G) * $SaturationLevel))
            $blue = [Math]::Round($grey.B + (($TintColor.B - $grey.B) * $SaturationLevel))
            
            $adjustedTintColor = [System.Drawing.Color]::FromArgb(255, $red, $green, $blue)
        }
        
        # Create color matrix for tinting white to accent color
        $colorMatrix = New-Object System.Drawing.Imaging.ColorMatrix
        
        # Set up matrix to replace white with tint color while preserving alpha
        $colorMatrix.Matrix00 = $adjustedTintColor.R / 255.0  # Red
        $colorMatrix.Matrix11 = $adjustedTintColor.G / 255.0  # Green  
        $colorMatrix.Matrix22 = $adjustedTintColor.B / 255.0  # Blue
        $colorMatrix.Matrix33 = 1.0                           # Alpha (preserve transparency)
        $colorMatrix.Matrix44 = 1.0                           # Required
        
        # Create image attributes with color matrix
        $imageAttributes = New-Object System.Drawing.Imaging.ImageAttributes
        $imageAttributes.SetColorMatrix($colorMatrix)
        
        # Draw the tinted image
        $destRect = New-Object System.Drawing.Rectangle(0, 0, $sourceImage.Width, $sourceImage.Height)
        $graphics.DrawImage($sourceImage, $destRect, 0, 0, $sourceImage.Width, $sourceImage.Height, [System.Drawing.GraphicsUnit]::Pixel, $imageAttributes)
        
        # Save as PNG
        $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Also create ICO version for better Windows integration
        $icoPath = $OutputPath -replace '\.png$', '.ico'
        $bitmap.Save($icoPath, [System.Drawing.Imaging.ImageFormat]::Icon)
        
        # Cleanup
        $graphics.Dispose()
        $bitmap.Dispose()
        $sourceImage.Dispose()
        $imageAttributes.Dispose()
        
        # Display saturation info if not full intensity
        if ($SaturationLevel -lt 1.0) {
            $saturationPercent = [Math]::Round($SaturationLevel * 100)
            Write-Host "✓ Created: $(Split-Path $OutputPath -Leaf) (${saturationPercent}% intensity)" -ForegroundColor Green
        } else {
            Write-Host "✓ Created: $(Split-Path $OutputPath -Leaf)" -ForegroundColor Green
        }
        return $true
    }
    catch {
        Write-Host "✗ Error processing $(Split-Path $SourcePath -Leaf): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create transparent version of an icon
function Convert-WhitePngToTransparent {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [float]$TransparencyLevel = 0.5
    )
    
    try {
        # Load the source image
        $sourceImage = [System.Drawing.Image]::FromFile($SourcePath)
        $bitmap = New-Object System.Drawing.Bitmap($sourceImage.Width, $sourceImage.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        
        # Create graphics object
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.Clear([System.Drawing.Color]::Transparent)
        
        # Create color matrix for transparency
        $colorMatrix = New-Object System.Drawing.Imaging.ColorMatrix
        $colorMatrix.Matrix33 = $TransparencyLevel  # Alpha channel
        $colorMatrix.Matrix44 = 1.0                 # Required
        
        # Create image attributes with color matrix
        $imageAttributes = New-Object System.Drawing.Imaging.ImageAttributes
        $imageAttributes.SetColorMatrix($colorMatrix)
        
        # Draw the transparent image
        $destRect = New-Object System.Drawing.Rectangle(0, 0, $sourceImage.Width, $sourceImage.Height)
        $graphics.DrawImage($sourceImage, $destRect, 0, 0, $sourceImage.Width, $sourceImage.Height, [System.Drawing.GraphicsUnit]::Pixel, $imageAttributes)
        
        # Save as PNG
        $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Also create ICO version
        $icoPath = $OutputPath -replace '\.png$', '.ico'
        $bitmap.Save($icoPath, [System.Drawing.Imaging.ImageFormat]::Icon)
        
        # Cleanup
        $graphics.Dispose()
        $bitmap.Dispose()
        $sourceImage.Dispose()
        $imageAttributes.Dispose()
        
        Write-Host "✓ Created transparent: $(Split-Path $OutputPath -Leaf)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Error creating transparent $(Split-Path $SourcePath -Leaf): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$iconsPath = Join-Path (Split-Path $scriptPath -Parent) "Icons"
$sourcePath = Join-Path $iconsPath "Source"
$tintedPath = Join-Path $iconsPath "Tinted"

Write-Host "=== Codex Icon Tinter ===" -ForegroundColor Cyan
Write-Host "Converting white PNG icons to brand-colored icons..." -ForegroundColor White

# Get theme mode
$themeMode = Get-WindowsThemeMode

Write-Host "Brand Primary: #3CA0FF (RGB($($brandPrimary.R), $($brandPrimary.G), $($brandPrimary.B)))" -ForegroundColor Cyan
Write-Host "Brand Accent: #A03CFF (RGB($($brandAccent.R), $($brandAccent.G), $($brandAccent.B)))" -ForegroundColor Magenta
Write-Host "Windows theme mode: $themeMode" -ForegroundColor Yellow

# Define power mode intensity levels and colors based on theme
if ($themeMode -eq "Dark") {
    # In dark mode, use slightly more vibrant colors for better visibility
    $powerModeSettings = @{
        "PowerSaver" = @{ Color = $brandPrimary; Intensity = 0.35 }   # 35% primary blue
        "Balanced" = @{ Color = $brandPrimary; Intensity = 0.70 }     # 70% primary blue
        "Performance" = @{ Color = $brandAccent; Intensity = 1.0 }    # 100% accent purple
    }
    Write-Host "Using Dark Mode intensity levels for better visibility" -ForegroundColor Cyan
} else {
    # In light mode, use standard intensity levels
    $powerModeSettings = @{
        "PowerSaver" = @{ Color = $brandPrimary; Intensity = 0.25 }   # 25% primary blue
        "Balanced" = @{ Color = $brandPrimary; Intensity = 0.60 }     # 60% primary blue  
        "Performance" = @{ Color = $brandAccent; Intensity = 1.0 }    # 100% accent purple
    }
    Write-Host "Using Light Mode intensity levels" -ForegroundColor Cyan
}

# Check if tinted icons already exist and not forcing
if ((Test-Path $tintedPath) -and (Get-ChildItem $tintedPath -Filter "*.png" -ErrorAction SilentlyContinue) -and (-not $Force)) {
    Write-Host "Tinted icons already exist. Use -Force to regenerate." -ForegroundColor Yellow
    exit
}

# Create tinted directory if it doesn't exist
if (-not (Test-Path $tintedPath)) {
    New-Item -ItemType Directory -Path $tintedPath -Force | Out-Null
}

# Process all PNG files in source directory
$sourceFiles = Get-ChildItem -Path $sourcePath -Filter "*.png" -ErrorAction SilentlyContinue

if ($sourceFiles.Count -eq 0) {
    Write-Host "No PNG files found in $sourcePath" -ForegroundColor Yellow
    Write-Host "Please add white PNG icons to the Source folder." -ForegroundColor Cyan    exit
}

$successCount = 0
$totalIcons = 0

foreach ($file in $sourceFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $outputPath = Join-Path $tintedPath $file.Name
    
    # Special handling for transparency icon
    if ($baseName -eq "Transparency") {
        Write-Host "Processing transparency icon: $baseName (50% transparency)" -ForegroundColor Cyan
        
        if (Convert-WhitePngToTransparent -SourcePath $file.FullName -OutputPath $outputPath -TransparencyLevel 0.5) {
            $successCount++
        }
        $totalIcons++
        continue
    }
    
    # Check if this is a power mode icon
    $isPowerModeIcon = $false
    $powerMode = ""
    
    foreach ($mode in $powerModeSettings.Keys) {
        if ($baseName -like "*$mode*") {
            $isPowerModeIcon = $true
            $powerMode = $mode
            break
        }
    }
    
    if ($isPowerModeIcon) {
        # Create power mode icon with specific brand color and intensity
        $settings = $powerModeSettings[$powerMode]
        $intensity = $settings.Intensity
        $color = $settings.Color
        
        Write-Host "Processing power mode icon: $baseName ($powerMode - $($intensity * 100)% intensity)" -ForegroundColor Cyan
        
        if (Convert-WhitePngToTintedIcon -SourcePath $file.FullName -OutputPath $outputPath -TintColor $color -SaturationLevel $intensity) {
            $successCount++
        }
        $totalIcons++
    } else {
        # Regular icon with primary brand color at full intensity
        Write-Host "Processing regular icon: $baseName" -ForegroundColor White
        
        if (Convert-WhitePngToTintedIcon -SourcePath $file.FullName -OutputPath $outputPath -TintColor $brandPrimary -SaturationLevel 1.0) {
            $successCount++
        }
        $totalIcons++
    }
}

Write-Host "`n=== Conversion Complete ===" -ForegroundColor Green
Write-Host "Successfully processed: $successCount/$totalIcons icons" -ForegroundColor White
Write-Host "Tinted icons saved to: $tintedPath" -ForegroundColor Cyan

# Show power mode intensity info
$powerModeCount = ($sourceFiles | Where-Object { 
    $_.BaseName -like "*PowerSaver*" -or $_.BaseName -like "*Balanced*" -or $_.BaseName -like "*Performance*" 
}).Count

if ($powerModeCount -gt 0) {
    Write-Host "`n=== Power Mode Icons ($themeMode Mode) ===" -ForegroundColor Yellow
    
    $psIntensity = [Math]::Round($powerModeSettings["PowerSaver"].Intensity * 100)
    $balIntensity = [Math]::Round($powerModeSettings["Balanced"].Intensity * 100)
    $perfIntensity = [Math]::Round($powerModeSettings["Performance"].Intensity * 100)
    
    Write-Host "• Power Saver icons: ${psIntensity}% primary blue intensity" -ForegroundColor DarkCyan
    Write-Host "• Balanced icons: ${balIntensity}% primary blue intensity" -ForegroundColor Cyan
    Write-Host "• Performance icons: ${perfIntensity}% accent purple intensity" -ForegroundColor Magenta
    
    if ($themeMode -eq "Dark") {
        Write-Host "  └─ Enhanced visibility for Dark Mode" -ForegroundColor Cyan
    } else {
        Write-Host "  └─ Subtle contrast for Light Mode" -ForegroundColor Cyan
    }
}

# Show notification
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info

if ($powerModeCount -gt 0) {
    $notify.BalloonTipText = "Generated $successCount custom icons with $themeMode Mode progressive intensities!"
} else {
    $notify.BalloonTipText = "Generated $successCount custom icons matching your Windows theme!"
}

$notify.BalloonTipTitle = "Codex - Icon Tinter"
$notify.Visible = $true
$notify.ShowBalloonTip(3000)

Start-Sleep 2
