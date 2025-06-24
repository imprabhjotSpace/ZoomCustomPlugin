#!/bin/bash

# Zoom VDI Plugin Setup Script
# This script sets up the Zoom VDI Helper plugin for macOS

set -e

# Configuration
PLUGIN_NAME="ZoomVDIHelper"
PLUGIN_BUNDLE="${PLUGIN_NAME}.bundle"
ZOOM_PLUGINS_DIR="$HOME/Library/Application Support/zoom.us/plugins"
ZOOM_CONFIG_DIR="$HOME/Library/Application Support/zoom.us"
PLUGIN_CONFIG_FILE="$ZOOM_CONFIG_DIR/vdi_plugin.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This plugin is only supported on macOS"
        exit 1
    fi
    log_info "macOS detected ✓"
}

# Check macOS version (require macOS 11.0 or later)
check_macos_version() {
    local version=$(sw_vers -productVersion)
    local major_version=$(echo $version | cut -d. -f1)
    local minor_version=$(echo $version | cut -d. -f2)
    
    if [[ $major_version -lt 11 ]]; then
        log_error "macOS 11.0 (Big Sur) or later is required. Current version: $version"
        exit 1
    fi
    log_info "macOS version $version is supported ✓"
}

# Check if Zoom is installed (latest path for user Applications)
check_zoom_installation() {
    local zoom_app="/Applications/zoom.us.app"
    if [[ ! -d "$zoom_app" ]]; then
        log_error "Zoom application not found at $zoom_app"
        log_error "Please install the latest Zoom (v6.0+) from https://zoom.us/download"
        exit 1
    fi
    log_info "Zoom installation found ✓"
}

# Check for required tools
check_dependencies() {
    local missing_deps=()
    
    # Check for Xcode command line tools
    if [[ "$xcode_path" != "/Applications/Xcode.app/Contents/Developer" ]]; then
        log_warning "xcode-select is not set to the full Xcode path."
        log_warning "Run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
        missing_deps+=("Correct Xcode toolchain")
    fi
    
    # Check for Swift compiler (Swift 6.0.3+)

    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "To install Xcode Command Line Tools, run: xcode-select --install"
        log_info "To update Swift, visit: https://www.swift.org/download/"
        exit 1
    fi
    
    log_info "All dependencies found ✓"
}

# Create necessary directories
create_directories() {
    log_info "Creating plugin directories..."
    
    mkdir -p "$ZOOM_PLUGINS_DIR"
    mkdir -p "$ZOOM_CONFIG_DIR"
    mkdir -p "$SCRIPT_DIR/build"
    
    log_success "Directories created"
}

# Build the plugin
build_plugin() {
    log_info "Building Zoom VDI Plugin..."
    
    cd "$SCRIPT_DIR"
    
    if [[ -f "Makefile" ]]; then
        make clean
        make all
    else
        log_error "Makefile not found. Please ensure all project files are present."
        exit 1
    fi
    
    if [[ ! -d "build/$PLUGIN_BUNDLE" ]]; then
        log_error "Plugin build failed"
        exit 1
    fi
    
    log_success "Plugin built successfully"
}

# Install the plugin
install_plugin() {
    log_info "Installing plugin to Zoom plugins directory..."
    
    # Remove existing plugin if present
    if [[ -d "$ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE" ]]; then
        log_warning "Removing existing plugin installation"
        rm -rf "$ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE"
    fi
    
    # Copy plugin bundle
    cp -R "$SCRIPT_DIR/build/$PLUGIN_BUNDLE" "$ZOOM_PLUGINS_DIR/"
    
    # Set proper permissions
    chmod -R 755 "$ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE"
    
    log_success "Plugin installed to $ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE"
}

# Create plugin configuration
create_config() {
    log_info "Creating plugin configuration..."
    
    cat > "$PLUGIN_CONFIG_FILE" << EOF
{
    "zoom_vdi_plugin": {
        "enabled": true,
        "plugin_path": "$ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE",
        "auto_start": true,
        "log_level": "info",
        "network": {
            "listen_port": 9001,
            "timeout_ms": 5000
        },
        "audio": {
            "enabled": true,
            "sample_rate": 48000,
            "channels": 2,
            "echo_cancellation": true
        },
        "video": {
            "enabled": true,
            "resolution": "1920x1080",
            "fps": 30,
            "hardware_acceleration": true
        }
    }
}
EOF
    
    log_success "Configuration created at $PLUGIN_CONFIG_FILE"
}

# Request necessary permissions
request_permissions() {
    log_info "Requesting system permissions..."
    
    # Camera permission
    log_info "Please grant camera access when prompted"
    
    # Microphone permission
    log_info "Please grant microphone access when prompted"
    
    # Create a small test app to trigger permission requests
    cat > /tmp/permission_test.swift << 'EOF'
import AVFoundation
import Foundation

let session = AVAudioSession.sharedInstance()
do {
    try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
    try session.setActive(true)
    print("Audio session configured")
} catch {
    print("Error configuring audio session: \(error)")
}

let captureSession = AVCaptureSession()
guard let videoDevice = AVCaptureDevice.default(for: .video) else {
    print("No video device found")
    exit(1)
}

do {
    let videoInput = try AVCaptureDeviceInput(device: videoDevice)
    print("Video input created")
} catch {
    print("Error creating video input: \(error)")
}

print("Permission requests completed")
EOF
    
    swiftc -framework AVFoundation -o /tmp/permission_test /tmp/permission_test.swift
    /tmp/permission_test
    rm -f /tmp/permission_test /tmp/permission_test.swift
    
    log_success "Permission requests completed"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if plugin bundle exists
    if [[ ! -d "$ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE" ]]; then
        log_error "Plugin bundle not found after installation"
        return 1
    fi
    
    # Check if plugin binary exists
    if [[ ! -f "$ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE/Contents/MacOS/ZoomVDIPlugin" ]]; then
        log_error "Plugin binary not found"
        return 1
    fi
    
    # Check if configuration exists
    if [[ ! -f "$PLUGIN_CONFIG_FILE" ]]; then
        log_error "Plugin configuration not found"
        return 1
    fi
    
    log_success "Installation verified ✓"
    return 0
}

# Create uninstall script
create_uninstall_script() {
    cat > "$SCRIPT_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# Zoom VDI Plugin Uninstaller

PLUGIN_BUNDLE="ZoomVDIHelper.bundle"
ZOOM_PLUGINS_DIR="$HOME/Library/Application Support/zoom.us/plugins"
PLUGIN_CONFIG_FILE="$HOME/Library/Application Support/zoom.us/vdi_plugin.conf"

echo "Uninstalling Zoom VDI Plugin..."

# Remove plugin bundle
if [[ -d "$ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE" ]]; then
    rm -rf "$ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE"
    echo "✓ Plugin bundle removed"
fi

# Remove configuration
if [[ -f "$PLUGIN_CONFIG_FILE" ]]; then
    rm -f "$PLUGIN_CONFIG_FILE"
    echo "✓ Configuration removed"
fi

echo "✅ Zoom VDI Plugin uninstalled successfully"
EOF
    
    chmod +x "$SCRIPT_DIR/uninstall.sh"
    log_success "Uninstall script created at $SCRIPT_DIR/uninstall.sh"
}

# Display usage instructions
show_usage_instructions() {
    cat << EOF

${GREEN}🎉 Zoom VDI Plugin Installation Complete!${NC}

${BLUE}USAGE INSTRUCTIONS:${NC}

1. ${YELLOW}Cloud PC Setup:${NC}
   - Install Zoom (v6.0 or later) on your Cloud PC (Windows 365/Azure Virtual Desktop)
   - Enable VDI optimization in Zoom settings
   - Configure the plugin to connect to your Mac IP address

2. ${YELLOW}Mac Configuration:${NC} 
   - The plugin is now listening on port 9001
   - Audio and video redirection will start automatically when Zoom VDI connects
   - Configuration file: $PLUGIN_CONFIG_FILE

3. ${YELLOW}Testing the Connection:${NC}
   - Start Zoom on your Cloud PC
   - Join a meeting - audio/video should redirect to your Mac
   - Check Console.app for plugin logs if issues occur

4. ${YELLOW}Troubleshooting:${NC}
   - Ensure firewall allows port 9001
   - Check System Settings > Privacy & Security for camera/microphone permissions
   - View logs: tail -f /tmp/zoom_vdi_plugin.log

${BLUE}CONFIGURATION:${NC}
- Plugin Location: $ZOOM_PLUGINS_DIR/$PLUGIN_BUNDLE
- Config File: $PLUGIN_CONFIG_FILE
- Uninstall: Run ./uninstall.sh

${BLUE}NETWORK REQUIREMENTS:${NC}
- Port 9001 must be open between Cloud PC and Mac
- Low latency network connection recommended
- Minimum 2 Mbps bandwidth for video calls

${GREEN}Need help? Check the documentation or contact support.${NC}

EOF
}

# Main installation function
main() {
    echo "================================================"
    echo "       Zoom VDI Plugin Setup for macOS"
    echo "================================================"
    echo
    
    # Perform all checks and installation steps
    check_macos
    check_macos_version
    check_zoom_installation
    check_dependencies
    
    log_info "Starting plugin installation..."
    
    create_directories
    build_plugin
    install_plugin
    create_config
    request_permissions
    
    if verify_installation; then
        create_uninstall_script
        show_usage_instructions
        log_success "Installation completed successfully!"
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "--uninstall")
        log_info "Uninstalling Zoom VDI Plugin..."
        if [[ -f "$SCRIPT_DIR/uninstall.sh" ]]; then
            bash "$SCRIPT_DIR/uninstall.sh"
        else
            log_error "Uninstall script not found"
            exit 1
        fi
        ;;
    "--help"|"-h")
        cat << EOF
Zoom VDI Plugin Setup Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    (no options)    Install the plugin
    --uninstall     Remove the plugin
    --help, -h      Show this help message

DESCRIPTION:
    This script installs the Zoom VDI Helper plugin for macOS, which enables
    audio and video redirection from Zoom running in a Cloud PC to your local Mac.

REQUIREMENTS:
    - macOS 11.0 or later
    - Zoom desktop client v6.0+ installed
    - Xcode Command Line Tools
    - Swift 5.10+ compiler
    - Camera and microphone permissions

EOF
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        log_info "Use --help for usage information"
        exit 1
        ;;
esac
