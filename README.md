# HP LaserJet M1132 Driver Installer for macOS 26+

A bash script that enables installation of HP LaserJet M1132 printer drivers on unsupported macOS versions (26.x Tahoe and beyond) by bypassing the operating system version check.

## ⚠️ Important Disclaimer

**These drivers are NOT officially supported on macOS 26+**

- This script only bypasses the installer's version check
- Use at your own risk
- Tested on: HP LaserJet M1132, MacBook Pro M3 Pro (macOS 26.2), MacBook Air M3 (macOS 26.1)

## What It Does

The HP printer driver package contains a version check that prevents installation on macOS versions newer than 15.0. This script:

1. Mounts the HP driver disk image
2. Extracts the installer package
3. Modifies the version check from `'15.0'` to `'30.0'` in the Distribution file
4. Rebuilds the installer package
5. Cleans up temporary files

The modified installer can then be used to install the drivers on macOS 26.x and future versions up to 30.0.

## Requirements

- **macOS Version**: 26.0 or higher (Tahoe)
- **HP Driver Package**: `HewlettPackardPrinterDrivers.dmg` (557 MB)
  - Place in: `~/Downloads/`
- **Printer Model**: HP LaserJet M1132 (may work with other HP models)
- **Architecture**: x86_64 drivers (works on Apple Silicon via Rosetta 2)

## Installation

### Step 1: Download HP Drivers

HP and Apple both provide the drivers, I've downloaded mine from HP directly using the newest available update (08-2022)

### Step 2: Run the Script

```bash
chmod +x ~/Downloads/install_hp_drivers_macos26.sh
~/Downloads/install_hp_drivers_macos26.sh
```

### Step 3: Install the Modified Package

After the script completes successfully, install the drivers using one of these methods:

**Method 1: GUI Installation (Recommended)**
```bash
open ~/Downloads/HP_Drivers.pkg
```
Then follow the on-screen installer prompts.

**Method 2: Terminal Installation**
```bash
sudo installer -pkg ~/Downloads/HP_Drivers.pkg -target /
```

### Step 4: Add Your Printer

1. Open **System Settings** > **Printers & Scanners**
2. Click the **+** button to add a printer
3. Select your HP LaserJet M1132 from the list
4. macOS should automatically select the HP driver
5. Click **Add**

## Troubleshooting

### "DMG file not found"
Ensure `HewlettPackardPrinterDrivers.dmg` is in `~/Downloads/`:
```bash
ls -lh ~/Downloads/HewlettPackardPrinterDrivers.dmg
```

### "Failed to mount DMG"
The DMG may already be mounted. Try unmounting first:
```bash
hdiutil eject "/Volumes/HP_PrinterSupportManual"
```

### Version string not found
If the script warns that `'15.0'` isn't found, the package may have a different version check. Review the displayed version checks and decide whether to continue.

### Printer not recognized after installation
1. Restart your Mac
2. Try removing and re-adding the printer in System Settings
3. Check **Printers & Scanners** > **Printer Software** to ensure HP drivers are listed

## Technical Details

### What Gets Modified

**Original Distribution file (line 16):**
```javascript
if (system.compareVersions(system.version.ProductVersion, '15.0') > 0) {
    my.result.message = system.localizedStringWithFormat('ERROR_25CBFE41C7', '15.0');
    my.result.type = 'Fatal';
    return false;
}
```

**Modified Distribution file (line 16):**
```javascript
if (system.compareVersions(system.version.ProductVersion, '30.0') > 0) {
    my.result.message = system.localizedStringWithFormat('ERROR_25CBFE41C7', '30.0');
    my.result.type = 'Fatal';
    return false;
}
```

This allows installation on macOS versions ≤ 30.0.

### Files Created

- **Input**: `~/Downloads/HewlettPackardPrinterDrivers.dmg` (557 MB)
- **Output**: `~/Downloads/HP_Drivers.pkg` (~557 MB)
- **Temporary**: `~/Downloads/hp-expanded/` (auto-deleted)

## Compatibility

### Tested On
- MacBook Pro M3 Pro - macOS 26.2 Tahoe
- MacBook Air M3 - macOS 26.1 Tahoe
- HP LaserJet M1132 MFP

### Should Work On
- macOS 26.0 - 29.x (any version ≤ 30.0)
- Intel and Apple Silicon Macs
- Other HP LaserJet models using the same driver package

## Uninstallation

To remove the HP drivers:

```bash
sudo rm -rf /Library/Printers/hp
sudo rm -rf /Library/Printers/PPDs/Contents/Resources/HP*
sudo pkgutil --forget com.apple.pkg.HewlettPackardPrinterDrivers
```

Then remove the printer from **System Settings** > **Printers & Scanners**.

## Credits

- Script concept based on community workarounds for installing legacy drivers
- [MacRumors forums](https://forums.macrumors.com/threads/monterrey-and-hp-printers.2319676/?post=30525559#post-30525559)
- [Burkhard Schmidt](https://github.molgen.mpg.de/pages/bs/macOSnotes/mac/mac_print_hpmonterey.html)

## License

This script is provided as-is for educational and personal use. Use at your own risk.

---

**Last Updated**: January 2026
**macOS Version**: 26.x Tahoe
**Printer Model**: HP LaserJet M1132 MFP
