# SnapClone iOS App

A complete iOS Snapchat clone built with SwiftUI, implementing core features like ephemeral messaging, camera functionality, and real-time communication.

## Features

### 🔐 Authentication
- Email/password registration and login
- Form validation with real-time feedback
- Secure credential storage with Keychain
- Password reset functionality

### 📸 Camera & Media
- Full camera integration with AVFoundation
- Front/back camera switching
- Flash and grid controls
- Photo capture and editing
- Text overlays and filters
- Photo library integration

### 👥 Friends System
- Add friends by username search
- Friend requests (send/accept/decline)
- Online status indicators
- Block/unblock functionality

### 💬 Messaging
- Real-time messaging with Firebase
- Ephemeral messages (auto-delete after viewing)
- Photo sharing with custom view duration
- Screenshot detection and notifications
- Message status tracking (sent/delivered/viewed)

### 🎨 UI/UX
- Dark mode optimized interface
- Snapchat-inspired yellow theme
- Smooth animations and transitions
- Responsive design for all screen sizes

## Architecture

### MVVM Pattern
- **Views**: SwiftUI components for UI
- **ViewModels**: ObservableObject classes managing state
- **Models**: Data structures for User, Message, Photo
- **Services**: Business logic and API communication

### Key Components
```
SnapClone/
├── Models/
│   ├── User.swift
│   ├── Message.swift
│   └── Photo.swift
├── Views/
│   ├── Authentication/
│   ├── Camera/
│   ├── Friends/
│   └── Profile/
├── ViewModels/
│   ├── AuthenticationViewModel.swift
│   ├── CameraViewModel.swift
│   └── FriendsViewModel.swift
├── Services/
│   ├── Firebase/
│   ├── Camera/
│   └── Storage/
└── Utilities/
    ├── KeychainHelper.swift
    └── Extensions/
```

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 15.0 or later
- Swift 5.9 or later
- Firebase account

### 1. Clone and Open Project
```bash
cd ios/SnapClone
open SnapClone.xcodeproj
```

### 2. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Add an iOS app with bundle ID `com.yourcompany.snapclone`
4. Download `GoogleService-Info.plist`
5. Replace the template file in `SnapClone/Resources/`
6. Enable Authentication, Firestore, and Storage in Firebase

### 3. Configure Firebase Services

#### Authentication
- Enable Email/Password provider
- Configure sign-in methods

#### Firestore Database
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // For friend search
    }
    
    // Messages collection
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.receiverId);
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
  }
}
```

#### Storage
```javascript
// Storage Security Rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /images/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    match /messages/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 4. Add Dependencies
In Xcode:
1. Select your project → Package Dependencies
2. Add these repositories:

```
Firebase iOS SDK:
https://github.com/firebase/firebase-ios-sdk.git

Kingfisher (Image Loading):
https://github.com/onevcat/Kingfisher.git
```

### 5. Configure Permissions
The `Info.plist` is already configured with necessary permissions:
- Camera access
- Photo library access
- Microphone access (for video)
- Push notifications

### 6. Build and Run
1. Select a device or simulator
2. Build and run the project (⌘+R)

## Key Features Implementation

### Ephemeral Messages
Messages automatically delete after being viewed:
```swift
// Message viewing logic
func markMessageAsViewed(_ messageId: String) async throws {
    // Set expiration time
    let expiresAt = Date().addingTimeInterval(viewDuration)
    
    // Schedule deletion
    DispatchQueue.main.asyncAfter(deadline: .now() + viewDuration) {
        deleteMessage(messageId)
    }
}
```

### Camera Integration
Full camera functionality with AVFoundation:
```swift
// Camera service setup
private func configureSession() {
    session.sessionPreset = .photo
    
    // Add video input
    let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
    session.addInput(videoDeviceInput)
    
    // Add photo output
    session.addOutput(photoOutput)
}
```

### Real-time Messaging
Firebase Firestore listeners for live updates:
```swift
func listenToMessages(for conversationId: String) -> AnyPublisher<[Message], Error> {
    let query = firestore.collection("messages")
        .whereField("conversationId", isEqualTo: conversationId)
        .order(by: "timestamp")
    
    return query.addSnapshotListener { snapshot, error in
        // Handle real-time updates
    }
}
```

## Security Considerations

### Data Protection
- Sensitive data stored in Keychain
- Firebase security rules implemented
- Screenshot detection for ephemeral content
- No hardcoded secrets in code

### Privacy
- Camera/photo permissions properly requested
- User data encrypted in transit
- Local caching with automatic cleanup
- Option to delete account and all data

## Testing

### Unit Tests
Run unit tests for ViewModels and Services:
```bash
⌘+U in Xcode
```

### UI Tests
Test user flows and interface interactions:
```bash
Create UI test target in Xcode
```

## Troubleshooting

### Common Issues

1. **Firebase not connecting**
   - Verify `GoogleService-Info.plist` is correctly added
   - Check bundle ID matches Firebase project

2. **Camera not working**
   - Ensure device has camera
   - Check permission settings
   - Test on physical device (not simulator)

3. **Build errors**
   - Clean build folder (⌘+Shift+K)
   - Update package dependencies
   - Check iOS deployment target

### Support
For issues and questions:
1. Check Firebase console for backend errors
2. Review Xcode console logs
3. Verify all dependencies are properly installed

## Performance Optimization

### Memory Management
- Automatic image cache management
- Proper cleanup of camera sessions
- Efficient message loading with pagination

### Network Optimization
- Image compression before upload
- Efficient Firestore queries
- Offline capability with local caching

## Future Enhancements

### Planned Features
- [ ] Video messaging
- [ ] Group chats
- [ ] Stories/timeline
- [ ] AR filters
- [ ] Location sharing
- [ ] Voice messages
- [ ] Dark mode toggle
- [ ] Custom themes

### Technical Improvements
- [ ] End-to-end encryption
- [ ] Background app refresh
- [ ] Apple Watch companion
- [ ] iPad optimization
- [ ] Accessibility improvements

## Contributing

1. Fork the repository
2. Create feature branch
3. Follow existing code style
4. Add unit tests for new features
5. Submit pull request

## License

This project is for educational purposes. Please respect Snapchat's intellectual property and trademarks.