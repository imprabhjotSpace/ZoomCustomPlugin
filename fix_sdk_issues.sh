#!/bin/bash

# Fix SDK and Xcode Command Line Tools Issues for macOS 14.5+
# This script resolves Swift compiler and SDK version mismatches

set -e

echo "🔧 Fixing SDK and Xcode Command Line Tools Issues..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Step 1: Check current versions
log_info "Checking current tool versions..."
echo "macOS Version: $(sw_vers -productVersion)"
echo "Xcode CLI Tools: $(xcode-select -p 2>/dev/null || echo 'Not installed')"
echo "Swift Version: $(swift --version 2>/dev/null || echo 'Not available')"

# Step 2: Remove and reinstall Xcode Command Line Tools
log_info "Removing existing Xcode Command Line Tools..."
sudo rm -rf /Library/Developer/CommandLineTools

log_info "Installing latest Xcode Command Line Tools..."
# This will prompt for installation
xcode-select --install

log_warning "Please complete the Xcode Command Line Tools installation in the popup window, then press Enter to continue..."
read -p "Press Enter after installation is complete..."

# Step 3: Reset Xcode path
log_info "Resetting Xcode developer path..."
sudo xcode-select --reset
sudo xcode-select --switch /Library/Developer/CommandLineTools

# Step 4: Clear Swift module cache
log_info "Clearing Swift module cache..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf /tmp/org.llvm.clang*

# Step 5: Accept license
log_info "Accepting Xcode license..."
sudo xcodebuild -license accept 2>/dev/null || true

# Step 6: Verify installation
log_info "Verifying installation..."
if xcode-select -p >/dev/null 2>&1; then
    log_success "Xcode Command Line Tools path: $(xcode-select -p)"
else
    log_error "Xcode Command Line Tools not properly installed"
    exit 1
fi

if swift --version >/dev/null 2>&1; then
    log_success "Swift compiler available: $(swift --version | head -1)"
else
    log_error "Swift compiler not available"
    exit 1
fi

log_success "SDK and tools updated successfully!"
echo
log_info "Now you can run the build again with: ./setup_script.sh" 