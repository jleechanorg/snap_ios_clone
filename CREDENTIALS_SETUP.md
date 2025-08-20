# 🔐 API Credentials Setup Guide

## 🚫 Important Security Notice
I cannot generate real API credentials for you - they must be created through official developer portals for security and terms of service compliance.

## 🔥 Firebase Setup

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `snapclone-ios`
4. Follow the setup wizard (disable Google Analytics if not needed)

### Step 2: Add iOS App to Firebase
1. In your Firebase project, click "Add app" → iOS
2. Enter iOS bundle ID: `com.snapclone.app`
3. Enter App nickname: `SnapClone`
4. Download `GoogleService-Info.plist`
5. Replace the template file at `/ios/SnapClone/SnapClone/GoogleService-Info.plist`

### Step 3: Enable Authentication
1. Go to Authentication → Sign-in method
2. Enable Email/Password provider
3. Enable Google provider (optional)

### Step 4: Set up Firestore
1. Go to Firestore Database
2. Click "Create database"
3. Start in test mode (for development)
4. Choose a location near you

### Step 5: Set up Storage
1. Go to Storage
2. Click "Get started"
3. Start in test mode
4. Use the same location as Firestore

## 📱 Snapchat API Setup

### Step 1: Create Snapchat Developer Account
1. Go to [Snapchat Developers](https://developers.snap.com/)
2. Click "Get Started" and create an account
3. Verify your email address

### Step 2: Create an App
1. Go to [Snap Kit Portal](https://kit.snapchat.com/)
2. Click "Create App"
3. Fill in app details:
   - **App Name**: SnapClone
   - **Description**: iOS Snapchat clone with real authentication
   - **Category**: Social
   - **Platform**: iOS

### Step 3: Configure Login Kit
1. In your app dashboard, go to "Login Kit"
2. Add iOS platform:
   - **Bundle ID**: `com.snapclone.app`
   - **Redirect URLs**: `snapclone://snap-kit/oauth2`
3. Note down your **Client ID**

### Step 4: Update Info.plist
Replace in `/ios/SnapClone/SnapClone/Info.plist`:
```xml
<key>SCSDKClientId</key>
<string>YOUR_ACTUAL_CLIENT_ID_HERE</string>
```

### Step 5: App Review (For Production)
- For development/testing, you can use the app immediately
- For App Store release, submit for Snap Kit review
- Review process typically takes 1-2 weeks

## 🔧 Development Configuration

### Required Fields in Info.plist:
```xml
<!-- Replace with your actual Snapchat Client ID -->
<key>SCSDKClientId</key>
<string>YOUR_SNAPCHAT_CLIENT_ID</string>

<!-- Redirect URL for OAuth2 -->
<key>SCSDKRedirectUrl</key>
<string>snapclone://snap-kit/oauth2</string>

<!-- Requested permissions -->
<key>SCSDKScopes</key>
<array>
    <string>https://auth.snapchat.com/oauth2/api/user.external_id</string>
    <string>https://auth.snapchat.com/oauth2/api/user.display_name</string>
    <string>https://auth.snapchat.com/oauth2/api/user.bitmoji.avatar</string>
</array>
```

### Firebase Configuration:
- Replace `GoogleService-Info.plist` with your downloaded file
- Bundle ID must match: `com.snapclone.app`

## 🧪 Testing Setup

### For Development Testing:
1. Use Firebase Test Mode (already configured)
2. Snapchat Login Kit works immediately after app creation
3. Test on iOS Simulator or real device

### For Production:
1. Configure Firebase Security Rules
2. Submit Snapchat app for review
3. Configure proper error handling

## ⚠️ Security Notes

- **Never commit real credentials to Git**
- **Use environment variables in CI/CD**
- **Configure Firebase Security Rules for production**
- **Follow Snapchat's brand guidelines**
- **Comply with both platforms' terms of service**

## 🚀 Next Steps After Setup

1. Replace template credentials with real ones
2. Create Xcode project from the generated code
3. Add Package Dependencies in Xcode
4. Build and test on iOS Simulator
5. Test Snapchat authentication flow

---

**📱 Ready to build your iOS Snapchat clone!**
*All code generated with Cerebras in 3.6 seconds*