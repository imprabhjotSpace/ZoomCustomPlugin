#!/bin/bash

# Fix Swift Toolchain and SDK Issues
# This script helps resolve the SDK version mismatch and SwiftBridging module conflicts

set -e

echo "🔧 Swift Toolchain and SDK Diagnostic Tool"
echo "=========================================="

# Check current setup
echo "📋 Current Setup:"
echo "Swift version: $(swift --version)"
echo "Xcode path: $(xcode-select -p)"
echo "SDK path: $(xcrun --show-sdk-path)"
echo "SDK version: $(xcrun --show-sdk-version)"
echo ""

# Option 1: Update Command Line Tools
echo "🛠️  Solution 1: Update Xcode Command Line Tools"
echo "Run this command to update your tools:"
echo "sudo xcode-select --install"
echo ""

# Option 2: Use different SDK
echo "🛠️  Solution 2: List available SDKs"
echo "Available SDKs:"
xcrun --show-sdk-path --sdk macosx
ls $(dirname $(xcrun --show-sdk-path))/*.sdk 2>/dev/null || echo "No additional SDKs found"
echo ""

# Option 3: Reset developer directory
echo "🛠️  Solution 3: Reset developer directory (if needed)"
echo "If you have multiple Xcode versions, reset to latest:"
echo "sudo xcode-select --reset"
echo ""

# Option 4: Clean build caches
echo "🛠️  Solution 4: Clean Swift module caches"
echo "rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "rm -rf ~/.cache/com.apple.dt.Xcode/*"
echo ""

# Check for module conflicts
echo "🔍 Checking for SwiftBridging module conflicts..."
BRIDGING_PATHS=$(find /Library/Developer/CommandLineTools -name "*bridging*" 2>/dev/null || true)
if [[ -n "$BRIDGING_PATHS" ]]; then
    echo "Found potential bridging module conflicts:"
    echo "$BRIDGING_PATHS"
else
    echo "No obvious bridging conflicts found"
fi
echo ""

# Recommended fix
echo "✅ RECOMMENDED SOLUTION:"
echo "1. Update Command Line Tools: sudo xcode-select --install"
echo "2. Clean build directory: make clean"
echo "3. Try building again: make all"
echo ""
echo "If that doesn't work:"
echo "4. Use explicit SDK: make SWIFT_FLAGS='-O -target x86_64-apple-macos10.15 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk'" 