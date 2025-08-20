# 🔥 Update Firebase Configuration

## Problem
Current GoogleService-Info.plist is missing CLIENT_ID keys needed for Google Sign-In.

## Solution
1. **Download complete config**: https://console.firebase.google.com/u/0/project/snapclone-c0a17/settings/general
2. **Find iOS app**: com.snapclone.app
3. **Download GoogleService-Info.plist**
4. **Replace file**:
```bash
mv ~/Downloads/GoogleService-Info.plist ios/SnapCloneApp/SnapCloneApp/GoogleService-Info.plist
```

## After Update
Your file should contain:
- ✅ API_KEY
- ✅ CLIENT_ID (for Google Sign-In)
- ✅ REVERSED_CLIENT_ID (for URL schemes)  
- ✅ PROJECT_ID
- ✅ BUNDLE_ID

## Then Use Cerebras
```bash
./.claude/commands/cerebras/cerebras_direct.sh "Update iOS SnapClone with complete Google Sign-In integration using the new GoogleService-Info.plist"
```

---
*Part of SnapClone iOS project with local .claude tools*