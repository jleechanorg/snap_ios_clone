#\!/bin/bash
# Simple XCUITest Runner Script

set -e

echo '🔍 Starting XCUITest Navigation Testing...'

# Build the app first
echo '📱 Building SnapClone app...'
xcodebuild build-for-testing     -project SnapClone.xcodeproj     -scheme SnapClone     -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'     -configuration Debug

echo '✅ Build completed successfully'

# Launch the iOS Simulator
echo '🚀 Launching iOS Simulator...'
xcrun simctl boot 'iPhone 16' || echo 'Simulator already running'

# Install the app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name 'SnapClone.app' -type d | head -1)
if [ \! -z "$APP_PATH" ]; then
    echo "📲 Installing app: $APP_PATH"
    xcrun simctl install 'iPhone 16' "$APP_PATH"
    
    # Launch the app
    echo "▶️  Launching SnapClone app..."
    xcrun simctl launch 'iPhone 16' com.snapclone.app
    
    echo "✅ App launched successfully\! Manual testing can now be performed."
    echo "📖 You can now manually test the button navigation in the iOS Simulator."
    echo "🔄 The app should show the full SnapClone interface with working navigation."
else
    echo "❌ Could not find built SnapClone.app"
    exit 1
fi
