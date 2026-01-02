#!/bin/bash

#############################################################################
#
# This script modifies the HP printer driver package to bypass the macOS
# version check, allowing installation on macOS 26. Tested on HP LaserJet 
# M1132 and MacBook Pro M3 Pro and MacBook Air M3, one at 26.2. and second
# on 26.1. Tahoe
#
#############################################################################

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DMG_FILE="$HOME/Downloads/HewlettPackardPrinterDrivers.dmg"
MOUNT_POINT="/Volumes/HP_PrinterSupportManual"
EXPAND_DIR="$HOME/Downloads/hp-expanded"
OUTPUT_PKG="$HOME/Downloads/HP_Drivers.pkg"
OLD_VERSION="'15.0'"
NEW_VERSION="'30.0'"

#############################################################################
# Helper Functions
#############################################################################

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

cleanup() {
    print_step "Cleaning up..."

    # Unmount DMG if mounted
    if [ -d "$MOUNT_POINT" ]; then
        hdiutil eject "$MOUNT_POINT" 2>/dev/null || true
    fi

    # Remove expanded directory
    if [ -d "$EXPAND_DIR" ]; then
        rm -rf "$EXPAND_DIR"
    fi
}

# Trap errors and cleanup
trap 'cleanup' EXIT

#############################################################################
# Main Script
#############################################################################

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  HP Driver Installer for macOS 26"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Step 1: Verify prerequisites
print_step "Checking prerequisites..."

if [ ! -f "$DMG_FILE" ]; then
    print_error "DMG file not found: $DMG_FILE"
    echo "Please ensure HewlettPackardPrinterDrivers.dmg is in ~/Downloads"
    exit 1
fi

print_success "Found DMG file ($(du -h "$DMG_FILE" | cut -f1))"

# Verify we're not running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Please do not run this script as root (using sudo)"
    echo "The script will ask for sudo only when needed for installation."
    exit 1
fi

# Step 2: Mount the DMG
print_step "Mounting HP driver disk image..."

# First, try to unmount if already mounted
hdiutil eject "$MOUNT_POINT" 2>/dev/null || true

hdiutil attach "$DMG_FILE" -readonly -nobrowse > /dev/null 2>&1

if [ ! -d "$MOUNT_POINT" ]; then
    print_error "Failed to mount DMG at $MOUNT_POINT"
    # Try alternate mount point (sometimes has a number suffix)
    ALT_MOUNT=$(find /Volumes -name "HP_PrinterSupportManual*" -type d 2>/dev/null | head -n 1)
    if [ -n "$ALT_MOUNT" ]; then
        MOUNT_POINT="$ALT_MOUNT"
        print_success "Mounted at: $MOUNT_POINT"
    else
        exit 1
    fi
else
    print_success "Mounted HP driver disk image"
fi

PKG_SOURCE="$MOUNT_POINT/HewlettPackardPrinterDrivers.pkg"

if [ ! -f "$PKG_SOURCE" ]; then
    print_error "Package file not found in mounted volume"
    exit 1
fi

# Step 3: Expand the installer package
print_step "Expanding installer package..."

# Remove old expanded directory if it exists
if [ -d "$EXPAND_DIR" ]; then
    rm -rf "$EXPAND_DIR"
fi

pkgutil --expand "$PKG_SOURCE" "$EXPAND_DIR"

if [ ! -f "$EXPAND_DIR/Distribution" ]; then
    print_error "Distribution file not found in expanded package"
    exit 1
fi

print_success "Package expanded successfully"

# Step 4: Modify version requirements
print_step "Modifying version check (${OLD_VERSION} → ${NEW_VERSION})..."

DISTRIBUTION_FILE="$EXPAND_DIR/Distribution"

# Check if the version string exists
if ! grep -q "$OLD_VERSION" "$DISTRIBUTION_FILE"; then
    print_warning "Version string $OLD_VERSION not found in Distribution file"
    echo "The package may have already been modified or has a different format."
    echo ""
    echo "Current version checks in Distribution file:"
    grep -n "ProductVersion\|compareVersions" "$DISTRIBUTION_FILE" || echo "None found"
    echo ""
    read -p "Do you want to continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    # Perform the modification
    sed -i '' "s/$OLD_VERSION/$NEW_VERSION/g" "$DISTRIBUTION_FILE"

    # Verify the change
    if grep -q "$NEW_VERSION" "$DISTRIBUTION_FILE"; then
        print_success "Version check modified successfully"
    else
        print_error "Failed to modify version check"
        exit 1
    fi
fi

# Step 5: Rebuild the package
print_step "Rebuilding installer package..."

# Remove old output package if it exists
if [ -f "$OUTPUT_PKG" ]; then
    rm -f "$OUTPUT_PKG"
fi

pkgutil --flatten "$EXPAND_DIR" "$OUTPUT_PKG"

if [ ! -f "$OUTPUT_PKG" ]; then
    print_error "Failed to create output package"
    exit 1
fi

print_success "Created modified installer: $OUTPUT_PKG"

echo ""
echo "═══════════════════════════════════════════════════════════════"
print_success "Installation package created successfully!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Modified package: $OUTPUT_PKG"
echo "Size: $(du -h "$OUTPUT_PKG" | cut -f1)"
echo ""
print_warning "IMPORTANT: These drivers are not officially supported on macOS 26"
echo ""
echo "To install the drivers, choose ONE of the following methods:"
echo ""
echo "  Method 1 (GUI):"
echo "    Double-click: $OUTPUT_PKG"
echo ""
echo "  Method 2 (Terminal):"
echo "    sudo installer -pkg \"$OUTPUT_PKG\" -target /"
echo ""