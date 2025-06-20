PLUGIN_NAME = ZoomVDIHelper
PLUGIN_BUNDLE = $(PLUGIN_NAME).bundle
BUILD_DIR = build
SWIFT_SRC = zoom_vdi_plugin.swift
BUNDLE_CONTENTS = $(BUILD_DIR)/$(PLUGIN_BUNDLE)/Contents
BUNDLE_MACOS = $(BUNDLE_CONTENTS)/MacOS
PLUGIN_BINARY = $(BUNDLE_MACOS)/ZoomVDIPlugin
SWIFTC = swiftc
SWIFT_FLAGS = -O -whole-module-optimization -sdk $(shell xcrun --show-sdk-path) -target x86_64-apple-macos10.15
FRAMEWORKS = -framework Foundation -framework AVFoundation -framework CoreAudio -framework IOKit -framework Network -framework VideoToolbox

.PHONY: all clean install uninstall help

all: $(PLUGIN_BUNDLE)

$(PLUGIN_BUNDLE): $(PLUGIN_BINARY) $(BUNDLE_CONTENTS)/Info.plist
	@echo "Plugin bundle created"

$(PLUGIN_BINARY): $(SWIFT_SRC) | $(BUNDLE_MACOS)
	@echo "Compiling Swift plugin..."
	$(SWIFTC) $(SWIFT_FLAGS) $(FRAMEWORKS) -emit-library -o $@ $<
	@chmod +x $@

$(BUNDLE_CONTENTS)/Info.plist: | $(BUNDLE_CONTENTS)
	@echo "Creating Info.plist..."
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $@
	@echo '<plist version="1.0">' >> $@
	@echo '<dict>' >> $@
	@echo '	<key>CFBundleExecutable</key>' >> $@
	@echo '	<string>ZoomVDIPlugin</string>' >> $@
	@echo '	<key>CFBundleIdentifier</key>' >> $@
	@echo '	<string>com.yourcompany.zoom.vdi.helper</string>' >> $@
	@echo '	<key>CFBundleName</key>' >> $@
	@echo '	<string>$(PLUGIN_NAME)</string>' >> $@
	@echo '	<key>CFBundlePackageType</key>' >> $@
	@echo '	<string>BNDL</string>' >> $@
	@echo '	<key>CFBundleVersion</key>' >> $@
	@echo '	<string>1.0.0</string>' >> $@
	@echo '	<key>NSPrincipalClass</key>' >> $@
	@echo '	<string>ZoomVDIPluginLoader</string>' >> $@
	@echo '	<key>ZoomPluginType</key>' >> $@
	@echo '	<string>VDI</string>' >> $@
	@echo '</dict>' >> $@
	@echo '</plist>' >> $@

$(BUNDLE_CONTENTS):
	@mkdir -p $(BUNDLE_CONTENTS)

$(BUNDLE_MACOS): $(BUNDLE_CONTENTS)
	@mkdir -p $(BUNDLE_MACOS)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)

help:
	@echo "Available targets: all, clean, help"

$(BUNDLE_CONTENTS): | $(BUILD_DIR) 