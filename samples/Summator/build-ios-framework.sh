#!/bin/bash

set -e

# Configuration
FRAMEWORK_NAME="Summator"
FRAMEWORK_VERSION="1.0"
OUTPUT_DIR="Game/lib/ios"
FRAMEWORK_DIR="$OUTPUT_DIR/$FRAMEWORK_NAME.framework"

echo "Building iOS Framework: $FRAMEWORK_NAME"

# Clean previous build
if [ -d "$FRAMEWORK_DIR" ]; then
    echo "Cleaning previous framework..."
    rm -rf "$FRAMEWORK_DIR"
fi

# Build the .NET library first
echo "Building .NET library for iOS..."
dotnet publish Extension -r ios-arm64 -o "$OUTPUT_DIR" --self-contained

# Check if dylib was created
if [ ! -f "$OUTPUT_DIR/Summator.dylib" ]; then
    echo "Error: Summator.dylib not found in $OUTPUT_DIR"
    exit 1
fi

# Create framework directory structure
echo "Creating framework structure..."
mkdir -p "$FRAMEWORK_DIR/Versions/A"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Headers"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Resources"

# Create symbolic links (standard iOS framework structure)
cd "$FRAMEWORK_DIR"
ln -sf "Versions/A/$FRAMEWORK_NAME" "$FRAMEWORK_NAME"
ln -sf "Versions/A/Headers" "Headers"
ln -sf "Versions/A/Resources" "Resources"
ln -sf "A" "Versions/Current"

# Copy the dylib to the framework
echo "Copying library to framework..."
cd - > /dev/null
cp "$OUTPUT_DIR/Summator.dylib" "$FRAMEWORK_DIR/Versions/A/$FRAMEWORK_NAME"

# Fix the install name to be self-contained within the framework
echo "Fixing install name..."
install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" "$FRAMEWORK_DIR/Versions/A/$FRAMEWORK_NAME"

# Create Info.plist
echo "Creating Info.plist..."
cat > "$FRAMEWORK_DIR/Versions/A/Resources/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.godot.$FRAMEWORK_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>$FRAMEWORK_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$FRAMEWORK_VERSION</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>MinimumOSVersion</key>
    <string>12.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
</dict>
</plist>
EOF

# Create module.modulemap for Swift/Objective-C interop
echo "Creating module map..."
cat > "$FRAMEWORK_DIR/Versions/A/Headers/module.modulemap" << EOF
framework module $FRAMEWORK_NAME {
    header "$FRAMEWORK_NAME.h"
    export *
}
EOF

# Create C header file
echo "Creating C header..."
cat > "$FRAMEWORK_DIR/Versions/A/Headers/$FRAMEWORK_NAME.h" << EOF
#ifndef SUMMATOR_H
#define SUMMATOR_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Main initialization function
bool summator_library_init(void* getProcAddress, void* library, void* initialization);

// Add other exported functions here as needed
// Example:
// int summator_add(int a, int b);

#ifdef __cplusplus
}
#endif

#endif /* SUMMATOR_H */
EOF

# Set proper permissions
chmod +x "$FRAMEWORK_DIR/Versions/A/$FRAMEWORK_NAME"

# Code signing
echo "Code signing framework..."

# Auto-detect signing identity if not provided
if [ -z "$SIGNING_IDENTITY" ]; then
    echo "Auto-detecting code signing identity..."
    AVAILABLE_IDENTITIES=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1)
    if [ -n "$AVAILABLE_IDENTITIES" ]; then
        SIGNING_IDENTITY=$(echo "$AVAILABLE_IDENTITIES" | sed 's/.*"\(.*\)".*/\1/')
        echo "Found signing identity: $SIGNING_IDENTITY"
    else
        echo "No Apple Development identity found. Checking for iPhone Developer..."
        AVAILABLE_IDENTITIES=$(security find-identity -v -p codesigning | grep "iPhone Developer" | head -1)
        if [ -n "$AVAILABLE_IDENTITIES" ]; then
            SIGNING_IDENTITY=$(echo "$AVAILABLE_IDENTITIES" | sed 's/.*"\(.*\)".*/\1/')
            echo "Found signing identity: $SIGNING_IDENTITY"
        else
            echo "No valid signing identity found. Please install a development certificate."
            exit 1
        fi
    fi
else
    echo "Using provided signing identity: $SIGNING_IDENTITY"
fi

TEAM_ID="${TEAM_ID:-}"

if [ -n "$TEAM_ID" ]; then
    SIGNING_FLAGS="--sign \"$SIGNING_IDENTITY\" --team \"$TEAM_ID\""
else
    SIGNING_FLAGS="--sign \"$SIGNING_IDENTITY\""
fi

# Sign the framework binary
echo "Signing with identity: $SIGNING_IDENTITY"
if [ -n "$TEAM_ID" ]; then
    codesign --force --sign "$SIGNING_IDENTITY" --team "$TEAM_ID" --timestamp --options runtime "$FRAMEWORK_DIR/Versions/A/$FRAMEWORK_NAME"
else
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime "$FRAMEWORK_DIR/Versions/A/$FRAMEWORK_NAME"
fi

# Verify the signature
echo "Verifying code signature..."
codesign --verify --verbose "$FRAMEWORK_DIR/Versions/A/$FRAMEWORK_NAME"

# Print framework info
echo ""
echo "Framework created successfully!"
echo "Framework location: $FRAMEWORK_DIR"
echo "Framework contents:"
find "$FRAMEWORK_DIR" -type f -exec echo "  {}" \;

# Verify the binary
echo ""
echo "Binary information:"
file "$FRAMEWORK_DIR/Versions/A/$FRAMEWORK_NAME"
otool -L "$FRAMEWORK_DIR/Versions/A/$FRAMEWORK_NAME" 2>/dev/null || echo "Note: otool not available or binary format not recognized"

# Show how to use the framework
echo ""
echo "To use this framework in Xcode:"
echo "1. Drag $FRAMEWORK_NAME.framework into your Xcode project"
echo "2. Add it to 'Frameworks, Libraries, and Embedded Content'"
echo "3. Set 'Embed & Sign' if needed"
echo "4. Import with: #import <$FRAMEWORK_NAME/$FRAMEWORK_NAME.h>"
echo ""
echo "Code signing is automatically detected. To override:"
echo "1. Set your signing identity: export SIGNING_IDENTITY=\"Your Developer Identity\""
echo "2. Set your team ID: export TEAM_ID=\"YOUR_TEAM_ID\""
echo "3. Available identities: security find-identity -v -p codesigning"

echo ""
echo "Framework build complete!"
