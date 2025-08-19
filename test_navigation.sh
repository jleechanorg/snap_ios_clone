#!/bin/bash

# 🚀🚀🚀 CEREBRAS GENERATED IN 8647ms 🚀🚀🚀
# iOS Navigation Flow Test Script

DEVICE_ID="A0045924-541C-47BE-A9F4-DC43CE0156D1"
BUNDLE_ID="com.snapclone.app"

echo "🔍 Testing SnapClone navigation flow..."

# Ensure device is booted
xcrun simctl boot $DEVICE_ID || echo "Device already booted"

# Launch app  
echo "📱 Launching SnapClone app..."
xcrun simctl launch $DEVICE_ID $BUNDLE_ID

# Wait for app to load
sleep 3

# Take initial screenshot
echo "📸 Taking login screen screenshot..."
xcrun simctl io $DEVICE_ID screenshot /tmp/test_login_screen.png

# Tap 'Sign In with Google' button (coordinates from earlier screenshot)
echo "👆 Tapping Sign In with Google button..."
xcrun simctl io $DEVICE_ID tap 361 1318

# Wait for navigation animation
sleep 3

# Take screenshot after tap
echo "📸 Taking post-login screenshot..."
xcrun simctl io $DEVICE_ID screenshot /tmp/test_main_app.png

echo "✅ Test completed!"
echo "📊 Results:"
echo "- Login screen: /tmp/test_login_screen.png"
echo "- Main app: /tmp/test_main_app.png"

# Check if the files were created and have reasonable sizes
login_size=$(stat -f%z /tmp/test_login_screen.png 2>/dev/null || echo "0")
main_size=$(stat -f%z /tmp/test_main_app.png 2>/dev/null || echo "0")

echo "📏 Screenshot sizes:"
echo "- Login: ${login_size} bytes"
echo "- Main: ${main_size} bytes"

if [ $login_size -gt 10000 ] && [ $main_size -gt 10000 ]; then
    echo "🎉 Navigation test appears successful!"
    if [ $main_size -ne $login_size ]; then
        echo "✅ Screenshots are different - navigation likely worked!"
    else
        echo "⚠️  Screenshots are same size - might still be on login screen"
    fi
else
    echo "❌ Test failed - screenshots too small or missing"
fi