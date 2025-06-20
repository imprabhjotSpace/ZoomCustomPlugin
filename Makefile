# Zoom VDI Plugin Makefile
# This Makefile builds the Zoom VDI Helper plugin for macOS

# Configuration
PLUGIN_NAME = ZoomVDIHelper
PLUGIN_BUNDLE = $(PLUGIN_NAME).bundle
BUILD_DIR = build
SWIFT_SRC = zoom_vdi_plugin.swift

# Bundle structure paths
BUNDLE_CONTENTS = $(BUILD_DIR)/$(PLUGIN_BUNDLE)/Contents
BUNDLE_MACOS = $(BUNDLE_CONTENTS)/MacOS
BUNDLE_RESOURCES = $(BUNDLE_CONTENTS)/Resources
PLUGIN_BINARY = $(BUNDLE_MACOS)/ZoomVDIPlugin

# Compiler and flags
SWIFTC = swiftc
SWIFT_FLAGS = -O -whole-module-optimization
FRAMEWORKS = -framework Foundation -framework AVFoundation -framework CoreAudio -framework IOKit -framework Network -framework VideoToolbox

# Default target
all: $(PLUGIN_BUNDLE)

# Create the plugin bundle
$(PLUGIN_BUNDLE): $(PLUGIN_BINARY) $(BUNDLE_CONTENTS)/Info.plist
	@echo "✅ Plugin bundle created: $(BUILD_DIR)/$(PLUGIN_BUNDLE)"

# Compile Swift source to plugin binary
$(PLUGIN_BINARY): $(SWIFT_SRC) | $(BUNDLE_MACOS)
	@echo "🔨 Compiling Swift plugin..."
	$(SWIFTC) $(SWIFT_FLAGS) $(FRAMEWORKS) -emit-library -o $@ $<
	@chmod +x $@
	@echo "✅ Plugin binary compiled"

# Create Info.plist for the bundle
$(BUNDLE_CONTENTS)/Info.plist: | $(BUNDLE_CONTENTS)
	@echo "📄 Creating bundle Info.plist..."
	@cat > $@ << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>ZoomVDIPlugin</string>
	<key>CFBundleIdentifier</key>
	<string>com.yourcompany.zoom.vdi.helper</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PLUGIN_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>BNDL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1.0.0</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2024 Your Company. All rights reserved.</string>
	<key>NSPrincipalClass</key>
	<string>ZoomVDIPluginLoader</string>
	<key>ZoomPluginType</key>
	<string>VDI</string>
	<key>ZoomPluginVersion</key>
	<string>1.0</string>
	<key>NSCameraUsageDescription</key>
	<string>This plugin needs camera access to redirect video from your Mac to Zoom on Cloud PC.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>This plugin needs microphone access to redirect audio from your Mac to Zoom on Cloud PC.</string>
</dict>
</plist>
EOF
	@echo "✅ Info.plist created"

# Create bundle directory structure
$(BUNDLE_CONTENTS):
	@echo "📁 Creating bundle directory structure..."
	@mkdir -p $(BUNDLE_CONTENTS)

$(BUNDLE_MACOS): $(BUNDLE_CONTENTS)
	@mkdir -p $(BUNDLE_MACOS)

$(BUNDLE_RESOURCES): $(BUNDLE_CONTENTS)
	@mkdir -p $(BUNDLE_RESOURCES)

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ Clean complete"

# Install plugin to Zoom plugins directory
install: $(PLUGIN_BUNDLE)
	@echo "📦 Installing plugin to Zoom plugins directory..."
	@ZOOM_PLUGINS_DIR="$$HOME/Library/Application Support/zoom.us/plugins" && \
	 mkdir -p "$$ZOOM_PLUGINS_DIR" && \
	 rm -rf "$$ZOOM_PLUGINS_DIR/$(PLUGIN_BUNDLE)" && \
	 cp -R "$(BUILD_DIR)/$(PLUGIN_BUNDLE)" "$$ZOOM_PLUGINS_DIR/" && \
	 echo "✅ Plugin installed to $$ZOOM_PLUGINS_DIR/$(PLUGIN_BUNDLE)"

# Uninstall plugin from Zoom plugins directory
uninstall:
	@echo "🗑️  Uninstalling plugin from Zoom plugins directory..."
	@ZOOM_PLUGINS_DIR="$$HOME/Library/Application Support/zoom.us/plugins" && \
	 rm -rf "$$ZOOM_PLUGINS_DIR/$(PLUGIN_BUNDLE)" && \
	 echo "✅ Plugin uninstalled"

# Show plugin info
info:
	@echo "Plugin Information:"
	@echo "  Name: $(PLUGIN_NAME)"
	@echo "  Bundle: $(PLUGIN_BUNDLE)"
	@echo "  Build Directory: $(BUILD_DIR)"
	@echo "  Swift Source: $(SWIFT_SRC)"
	@echo "  Binary Location: $(PLUGIN_BINARY)"

# Help target
help:
	@echo "Zoom VDI Plugin Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all        - Build the plugin bundle (default)"
	@echo "  clean      - Remove build artifacts"
	@echo "  install    - Install plugin to Zoom plugins directory"
	@echo "  uninstall  - Remove plugin from Zoom plugins directory"
	@echo "  info       - Show plugin information"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  - macOS 10.15 or later"
	@echo "  - Xcode Command Line Tools"
	@echo "  - Swift compiler (swiftc)"

# Declare phony targets
.PHONY: all clean install uninstall info help

# Create build directory dependency
$(BUNDLE_CONTENTS): | $(BUILD_DIR) 