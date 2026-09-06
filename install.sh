#!/bin/bash
set -e

echo "🔨 Building Deen+ for your device..."
xcodebuild -project "Deen+.xcodeproj" -scheme "Deen+" -destination "generic/platform=iOS" build -quiet

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Deen+-* -name "Deen.app" -path "*/Debug-iphoneos/*" | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not locate built Deen.app"
    exit 1
fi

echo "📲 Installing Deen.app onto your connected device (without launching)..."
xcrun devicectl device install app --device "MiPhone" "$APP_PATH"

echo "✅ Installed successfully on MiPhone!"
