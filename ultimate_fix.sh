#!/bin/bash

# Ultimate Fix for Zoom VDI Plugin Compilation on macOS 14.5+
# This script fixes all SDK, Xcode CLI Tools, and compilation issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

echo "=========================================="
echo "🚀 ULTIMATE ZOOM VDI PLUGIN FIX SCRIPT"
echo "=========================================="
echo

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script must be run on macOS"
    exit 1
fi

MACOS_VERSION=$(sw_vers -productVersion)
log_info "macOS Version: $MACOS_VERSION"

# Step 1: Backup and clean existing installations
log_step "1. Cleaning existing SDK and build artifacts..."

# Clean build directory
rm -rf build/ 2>/dev/null || true

# Clean Swift module caches
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true
rm -rf /tmp/org.llvm.clang* 2>/dev/null || true

log_success "Cleaned existing caches and build artifacts"

# Step 2: Fix Xcode Command Line Tools
log_step "2. Fixing Xcode Command Line Tools..."

# Remove existing tools if they're causing issues
if [ -d "/Library/Developer/CommandLineTools" ]; then
    log_warning "Removing potentially corrupted Command Line Tools..."
    sudo rm -rf /Library/Developer/CommandLineTools
fi

# Install fresh Command Line Tools
log_info "Installing fresh Xcode Command Line Tools..."
if ! xcode-select --install 2>/dev/null; then
    log_warning "Command Line Tools may already be installed or installation in progress"
fi

# Wait for installation or skip if already installed
log_warning "If installation popup appeared, complete it. Otherwise, continuing..."
sleep 3

# Reset and configure Xcode paths
sudo xcode-select --reset
if [ -d "/Applications/Xcode.app" ]; then
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    log_info "Using full Xcode installation"
else
    sudo xcode-select --switch /Library/Developer/CommandLineTools
    log_info "Using Command Line Tools"
fi

# Accept license
sudo xcodebuild -license accept 2>/dev/null || log_warning "License already accepted or not needed"

log_success "Xcode tools configured"

# Step 3: Verify and fix Swift installation
log_step "3. Verifying Swift installation..."

SWIFT_PATH=$(xcrun -f swiftc 2>/dev/null || echo "")
SDK_PATH=$(xcrun --show-sdk-path 2>/dev/null || echo "")

if [ -z "$SWIFT_PATH" ] || [ -z "$SDK_PATH" ]; then
    log_error "Swift compiler or SDK not found. Please install Xcode Command Line Tools manually:"
    log_error "Run: xcode-select --install"
    exit 1
fi

log_success "Swift compiler: $SWIFT_PATH"
log_success "SDK path: $SDK_PATH"

# Step 4: Create optimized Makefile
log_step "4. Creating optimized Makefile..."

cat > Makefile.optimized << 'EOF'
PLUGIN_NAME = ZoomVDIHelper
PLUGIN_BUNDLE = $(PLUGIN_NAME).bundle
BUILD_DIR = build
SWIFT_SRC = zoom_vdi_plugin.swift
BUNDLE_CONTENTS = $(BUILD_DIR)/$(PLUGIN_BUNDLE)/Contents
BUNDLE_MACOS = $(BUNDLE_CONTENTS)/MacOS
PLUGIN_BINARY = $(BUNDLE_MACOS)/ZoomVDIPlugin

# Dynamic tool and SDK detection
SWIFTC = $(shell xcrun -f swiftc)
SDK_PATH = $(shell xcrun --show-sdk-path)
PLATFORM = $(shell uname -m)

# Optimized flags for macOS 14.5+
SWIFT_FLAGS = -O -sdk $(SDK_PATH) -target $(PLATFORM)-apple-macos10.15 -module-cache-path /tmp/swift-cache
FRAMEWORKS = -framework Foundation -framework AVFoundation -framework CoreAudio -framework IOKit -framework Network

.PHONY: all clean test info

all: info $(PLUGIN_BUNDLE)

info:
	@echo "Build Configuration:"
	@echo "  Swift: $(SWIFTC)"
	@echo "  SDK: $(SDK_PATH)" 
	@echo "  Platform: $(PLATFORM)"
	@echo "  Target: $(PLATFORM)-apple-macos10.15"

$(PLUGIN_BUNDLE): $(PLUGIN_BINARY) $(BUNDLE_CONTENTS)/Info.plist
	@echo "✅ Plugin bundle created: $(BUILD_DIR)/$(PLUGIN_BUNDLE)"

$(PLUGIN_BINARY): $(SWIFT_SRC) | $(BUNDLE_MACOS)
	@echo "🔨 Compiling Swift plugin..."
	@mkdir -p /tmp/swift-cache
	$(SWIFTC) $(SWIFT_FLAGS) $(FRAMEWORKS) -emit-library -o $@ $<
	@chmod +x $@
	@echo "✅ Compilation successful"

$(BUNDLE_CONTENTS)/Info.plist: | $(BUNDLE_CONTENTS)
	@echo "📄 Creating Info.plist..."
	@cat > $@ << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>ZoomVDIPlugin</string>
	<key>CFBundleIdentifier</key>
	<string>com.yourcompany.zoom.vdi.helper</string>
	<key>CFBundleName</key>
	<string>$(PLUGIN_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>BNDL</string>
	<key>CFBundleVersion</key>
	<string>1.0.0</string>
	<key>NSPrincipalClass</key>
	<string>ZoomVDIPluginLoader</string>
	<key>ZoomPluginType</key>
	<string>VDI</string>
	<key>NSCameraUsageDescription</key>
	<string>Camera access for video redirection</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>Microphone access for audio redirection</string>
</dict>
</plist>
PLIST

$(BUNDLE_CONTENTS):
	@mkdir -p $(BUNDLE_CONTENTS)

$(BUNDLE_MACOS): $(BUNDLE_CONTENTS)
	@mkdir -p $(BUNDLE_MACOS)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)
	@rm -rf /tmp/swift-cache
	@echo "🧹 Build artifacts cleaned"

test: $(PLUGIN_BUNDLE)
	@echo "🧪 Testing plugin bundle..."
	@if [ -f "$(PLUGIN_BINARY)" ]; then \
		echo "✅ Plugin binary exists"; \
		file "$(PLUGIN_BINARY)"; \
	else \
		echo "❌ Plugin binary missing"; \
	fi

$(BUNDLE_CONTENTS): | $(BUILD_DIR)
EOF

log_success "Optimized Makefile created"

# Step 5: Test compilation
log_step "5. Testing compilation..."

if make -f Makefile.optimized clean && make -f Makefile.optimized all; then
    log_success "🎉 COMPILATION SUCCESSFUL!"
    
    # Verify the build
    if [ -f "build/ZoomVDIHelper.bundle/Contents/MacOS/ZoomVDIPlugin" ]; then
        log_success "Plugin binary created successfully"
        file "build/ZoomVDIHelper.bundle/Contents/MacOS/ZoomVDIPlugin"
    fi
    
    echo
    echo "=========================================="
    echo "🎯 BUILD COMPLETE - READY TO USE!"
    echo "=========================================="
    echo
    log_info "Plugin location: $(pwd)/build/ZoomVDIHelper.bundle"
    log_info "Next step: Run ./setup_script.sh to install the plugin"
    
else
    log_error "Compilation failed. Trying fallback method..."
    
    # Fallback: Direct compilation
    log_step "6. Trying direct compilation fallback..."
    
    mkdir -p build/ZoomVDIHelper.bundle/Contents/MacOS
    
    if xcrun swiftc -O -sdk "$(xcrun --show-sdk-path)" \
       -target "$(uname -m)-apple-macos10.15" \
       -framework Foundation -framework AVFoundation \
       -framework CoreAudio -framework IOKit -framework Network \
       -emit-library -o build/ZoomVDIHelper.bundle/Contents/MacOS/ZoomVDIPlugin \
       zoom_vdi_plugin.swift; then
        
        log_success "🎉 FALLBACK COMPILATION SUCCESSFUL!"
        
        # Create minimal Info.plist
        cat > build/ZoomVDIHelper.bundle/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>ZoomVDIPlugin</string>
	<key>CFBundleIdentifier</key>
	<string>com.yourcompany.zoom.vdi.helper</string>
	<key>CFBundleName</key>
	<string>ZoomVDIHelper</string>
	<key>CFBundlePackageType</key>
	<string>BNDL</string>
	<key>CFBundleVersion</key>
	<string>1.0.0</string>
	<key>NSPrincipalClass</key>
	<string>ZoomVDIPluginLoader</string>
</dict>
</plist>
EOF
        
        chmod +x build/ZoomVDIHelper.bundle/Contents/MacOS/ZoomVDIPlugin
        
        echo
        echo "=========================================="
        echo "🎯 FALLBACK BUILD COMPLETE!"
        echo "=========================================="
        
    else
        log_error "Both compilation methods failed."
        log_error "Please check your Xcode installation and try again."
        exit 1
    fi
fi

echo
log_info "🔧 Setup completed successfully!"
log_info "💡 Use 'make -f Makefile.optimized' for future builds"
echo 