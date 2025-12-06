#!/bin/bash

# Setup script for iOS Net Override
# This script configures bundle identifiers and app group for your Apple Developer account

set -e

echo "🔧 iOS Net Override - Setup Configuration"
echo "=========================================="
echo ""

# Get user input
read -p "Enter your base bundle identifier (e.g., com.yourname.NetOverride): " BUNDLE_ID

if [ -z "$BUNDLE_ID" ]; then
    echo "❌ Bundle identifier cannot be empty"
    exit 1
fi

# Derive other identifiers
EXTENSION_BUNDLE_ID="${BUNDLE_ID}.netextension"
APP_GROUP_ID="group.${BUNDLE_ID}"

echo ""
echo "📋 Configuration Summary:"
echo "  App Bundle ID:       $BUNDLE_ID"
echo "  Extension Bundle ID: $EXTENSION_BUNDLE_ID"
echo "  App Group ID:        $APP_GROUP_ID"
echo ""

read -p "Continue with these values? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ Setup cancelled"
    exit 0
fi

echo ""
echo "🔄 Updating configuration files..."

# Update AppConfig.swift
if [ -f "AppConfig.swift" ]; then
    sed -i '' "s|case appExtensionBundleIdentifier = \".*\"|case appExtensionBundleIdentifier = \"$EXTENSION_BUNDLE_ID\"|g" AppConfig.swift
    sed -i '' "s|case appGroupIdentifier = \".*\"|case appGroupIdentifier = \"$APP_GROUP_ID\"|g" AppConfig.swift
    echo "  ✅ Updated AppConfig.swift"
else
    echo "  ⚠️  AppConfig.swift not found"
fi

# Update project.pbxproj
if [ -f "NetOverride.xcodeproj/project.pbxproj" ]; then
    sed -i '' "s|PRODUCT_BUNDLE_IDENTIFIER = xyz.yashyn.NetOverride;|PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;|g" NetOverride.xcodeproj/project.pbxproj
    sed -i '' "s|PRODUCT_BUNDLE_IDENTIFIER = xyz.yashyn.NetOverride.netextension;|PRODUCT_BUNDLE_IDENTIFIER = $EXTENSION_BUNDLE_ID;|g" NetOverride.xcodeproj/project.pbxproj
    echo "  ✅ Updated project.pbxproj"
else
    echo "  ⚠️  project.pbxproj not found"
fi

# Update entitlements files
if [ -f "NetOverride/NetOverride.entitlements" ]; then
    sed -i '' "s|<string>group.xyz.yashyn.NetOverride</string>|<string>$APP_GROUP_ID</string>|g" NetOverride/NetOverride.entitlements
    echo "  ✅ Updated NetOverride.entitlements"
else
    echo "  ⚠️  NetOverride.entitlements not found"
fi

if [ -f "netextension/netextension.entitlements" ]; then
    sed -i '' "s|<string>group.xyz.yashyn.NetOverride</string>|<string>$APP_GROUP_ID</string>|g" netextension/netextension.entitlements
    echo "  ✅ Updated netextension.entitlements"
else
    echo "  ⚠️  netextension.entitlements not found"
fi

echo ""
echo "✅ Configuration complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Open NetOverride.xcodeproj in Xcode"
echo "  2. For each target (NetOverride and netextension):"
echo "     - Go to Signing & Capabilities"
echo "     - Select your development team"
echo "     - Verify the bundle identifiers and app group"
echo "  3. Build and run on your device"
echo ""
echo "⚠️  Remember to create the App Group '$APP_GROUP_ID' in your Apple Developer account"
echo "    https://developer.apple.com/account/resources/identifiers/list/applicationGroup"
echo ""
