# 🔥 Firebase Setup Quick Reference

## ✅ Project Configuration
```
Project Name: snapclone-ios
iOS Bundle ID: com.snapclone.app
App Nickname: SnapClone
```

## 📁 File Replacement
**CRITICAL**: Replace template with your downloaded file:
```bash
# Move downloaded file to project
mv ~/Downloads/GoogleService-Info.plist /Users/jleechan/projects/snap_ios_clone/ios/SnapCloneApp/SnapCloneApp/GoogleService-Info.plist
```

## 🔧 Services to Enable

### 🔐 Authentication
- ✅ Email/Password sign-in method

### 🗄️ Firestore Database  
- ✅ Test mode (for development)
- ✅ Location: us-central1

### 📁 Storage
- ✅ Test mode
- ✅ Same location as Firestore

## 🚀 After Setup
Your app will have:
- Real Firebase backend
- User authentication 
- Cloud database
- File/image storage
- Works with Snapchat login integration

---
*Part of SnapClone iOS project*