# SnapClone iOS Views Specification

## Overview
The SnapClone app contains **14 distinct views** organized into 6 main categories, implementing a camera-first social messaging experience with ephemeral content.

## View Count Summary
- **Main App Views**: 5 views (Authentication, Camera, Stories, Chat, Profile)
- **Camera Related**: 4 views (CameraView, SharePhotoView, CameraPreviewView, CapturedImageView)
- **Friends & Social**: 3 views (FriendsListView, AddFriendsView, ConversationView)
- **Supporting Views**: 2 views (PhotoPicker, StoryDetailView)

---

## 1. Authentication Views

### AuthenticationView
**Purpose**: Login/signup entry point with animated yellow gradient background
**Design Specifications**:
- **Background**: Linear gradient from yellow (0.9, 0.9, 0.0) to orange (1.0, 0.8, 0.0)
- **Logo**: Large camera.circle.fill icon (80pt) with white color and shadow
- **Title**: "SnapClone" in large title font, bold, white with shadow
- **Layout**: Centered vertically with keyboard-aware scrolling
- **Forms**: Two-mode interface (SignIn/SignUp) with smooth transitions

**Components**:
- **CustomTextField**: White rounded background (opacity 0.9), 15px corner radius, red validation borders
- **CustomSecureField**: Same as text field but with show/hide password toggle (eye icon)
- **Buttons**: 
  - Primary: White background, black text, 25px corner radius, 50px height
  - Secondary: Blue background for Google sign-in
  - Links: White underlined text for mode switching

**SignIn Form**:
- Email field with email keyboard type
- Password field with secure entry
- "Forgot Password?" link (right-aligned)
- Sign In button (disabled state with gray background)
- "Don't have an account? Sign Up" link
- Google Sign-In option below divider

**SignUp Form**:
- Email, Username, Display Name, Password, Confirm Password fields
- Real-time validation messages with warning icons
- Field-specific validation feedback (red borders, error text)
- Terms acceptance (implied)
- "Already have an account? Sign In" link

**ForgotPasswordView** (Sheet):
- Simple modal with email input
- "Send Reset Link" button
- Cancel button in navigation bar

---

## 2. Main Camera Interface

### CameraView (Primary Interface)
**Purpose**: Core camera functionality - the app opens directly to this view
**Design Specifications**:
- **Background**: Full-screen black background
- **Permission State**: Shows CameraPermissionView if access denied
- **Photo State**: Shows PhotoEditView after capture
- **Default State**: Shows CameraPreviewView for live camera

**Layout**:
- Full-screen camera preview (ignores safe areas)
- Overlay controls positioned over camera feed
- Bottom control bar with camera controls
- Status indicators and flash controls at top

**States**:
1. **Permission Required**: CameraPermissionView with access request
2. **Live Preview**: Real-time camera feed with controls
3. **Photo Captured**: PhotoEditView with editing options
4. **Error State**: Alert dialogs for camera errors

### CameraPreviewView
**Purpose**: Live camera preview with capture controls
**Design Specifications**:
- **Preview**: Full-screen AVFoundation camera preview layer
- **Controls Overlay**: Semi-transparent black overlays for controls
- **Bottom Bar**: 150px height control area with camera controls

**Control Layout**:
- **Flash Button** (Left): bolt.fill/bolt.slash.fill icon, 24pt font, white color
- **Capture Button** (Center): 
  - Outer circle: 70px diameter, white stroke (4px width)
  - Inner circle: 60px diameter, solid white fill
  - Tap animation: gray fill during capture
- **Camera Switch** (Right): camera.rotate.fill icon, 24pt font, white color
- **Photo Library** (Bottom Left): Small thumbnail or gallery icon

**Gestures**:
- Tap capture button: Take photo
- Hold capture button: Start video recording (future feature)
- Swipe left/right: Switch between camera modes
- Pinch: Zoom in/out on camera preview

### SharePhotoView
**Purpose**: Post-capture photo sharing interface
**Design Specifications**:
- **Header**: "Share Photo" title with close button
- **Preview**: Large photo preview (maintaining aspect ratio)
- **Friends List**: Scrollable list of friends with checkboxes
- **Text Overlay**: Optional text input for captions
- **Send Button**: Yellow accent button, full width, bottom of screen

**Features**:
- Multi-friend selection with visual checkmarks
- Caption text overlay with positioning controls
- Timer setting (3, 5, 10 seconds, or "No Limit")
- Send to Story vs. Direct Message toggle

### CapturedImageView
**Purpose**: Immediate post-capture preview and basic editing
**Design Specifications**:
- **Background**: Black full-screen
- **Image**: Centered photo maintaining aspect ratio
- **Controls Overlay**: Semi-transparent overlays
- **Bottom Actions**: Retake, Edit, Share buttons

**Action Buttons**:
- **Retake**: Arrow counterclockwise icon, left side
- **Edit**: Leads to editing tools (crop, filter, text)
- **Share**: Checkmark or share icon, primary action

---

## 3. Stories & Social Content

### StoriesView
**Purpose**: View friends' 24-hour ephemeral stories
**Design Specifications**:
- **Background**: White background with pull-to-refresh
- **Header**: "Stories" navigation title
- **Empty State**: 
  - 📖 emoji (60pt, 0.6 opacity)
  - "No Stories Yet" headline
  - "Stories from your friends will appear here" caption

**Story List Design**:
- **LazyVStack**: Scrollable list with 15px spacing
- **Story Rows**: Each story as a StoryRowView component
- **Loading State**: Centered ProgressView with "Loading stories..."

### StoryRowView Component
**Design Specifications**:
- **Height**: 80px per row with 8px vertical padding
- **Layout**: HStack with 15px spacing between elements

**Elements**:
- **Avatar Circle**: 
  - 60px diameter blue circle (opacity 0.3)
  - User's first initial in white, title2 font, semibold
- **Content Column**:
  - Username in headline font, primary color
  - Timestamp in relative style (caption font, secondary color)
  - Status indicator: "• Active" (green) or "• Expired" (red)
- **Thumbnail**:
  - 50x70px rounded rectangle (8px corner radius)
  - Gray background with photo icon placeholder
  - Actual story preview in production

**Interaction**: Tap gesture navigates to StoryDetailView

### StoryDetailView
**Purpose**: Full-screen story viewing with navigation
**Design Specifications**:
- **Background**: Black full-screen
- **Content**: Full-screen image/video with aspect-fill
- **Progress Bar**: Top of screen showing story duration
- **Navigation**: Tap left/right sides to navigate between stories
- **User Info**: Username and timestamp overlay at top
- **Exit**: Swipe down to dismiss or automatic progression

---

## 4. Messaging Interface

### ChatView
**Purpose**: Conversations list with recent messages
**Design Specifications**:
- **Background**: White with navigation view
- **Header**: "Chat" title with refresh capability
- **Empty State**:
  - 💬 emoji (60pt, 0.6 opacity)
  - "No Conversations" headline
  - "Start chatting with your friends!" caption

**Conversation List**:
- **Layout**: Standard List with PlainListStyle
- **Row Design**: ConversationRowView components
- **Navigation**: Each row navigates to ConversationView

### ConversationRowView Component
**Design Specifications**:
- **Height**: 70px with 8px vertical padding
- **Layout**: HStack with 15px spacing

**Elements**:
- **Avatar**: 50px blue circle with user's initial (white text, headline font)
- **Content Column**:
  - **Top Row**: Username (headline) and timestamp (caption, right-aligned)
  - **Bottom Row**: Last message preview (body font, secondary color, 1 line limit)
- **Unread Badge**: 
  - Red capsule with white count text
  - Only visible when unreadCount > 0
  - 8px horizontal, 4px vertical padding

### ConversationView
**Purpose**: Individual chat conversation interface
**Design Specifications**:
- **Background**: White or light gray chat background
- **Header**: Contact name with back button
- **Message Area**: Scrollable message list with bubble design
- **Input Area**: Text field with send button at bottom

**Message Bubbles**:
- **Sent Messages**: Blue bubbles, right-aligned
- **Received Messages**: Gray bubbles, left-aligned
- **Timestamp**: Small gray text below bubbles
- **Status**: Read receipts and delivery indicators

---

## 5. Social Features

### FriendsListView
**Purpose**: Manage friends and friend requests
**Design Specifications**:
- **Background**: White with navigation
- **Header**: "Friends" title with add button
- **Sections**: 
  - Friend requests (if any)
  - Current friends list
  - Suggested friends

**Friend Row Design**:
- Profile picture (circular, 40px)
- Username and display name
- Action buttons (Accept/Decline for requests, Remove for friends)

### AddFriendsView
**Purpose**: Search and add new friends
**Design Specifications**:
- **Search Bar**: Top of screen with real-time search
- **Results List**: Searchable user list
- **User Rows**: Profile picture, username, "Add Friend" button
- **Suggestions**: Nearby users or mutual connections

---

## 6. Profile & Settings

### ProfileView
**Purpose**: User profile management and app settings
**Design Specifications**:
- **Background**: White with navigation
- **Header**: "Profile" large title, bold, centered

**Profile Section**:
- **Avatar**: 100px yellow circle with 😎 emoji (40pt font)
- **Username**: From AuthenticationViewModel.currentUser.email or "jleechan"
- **Subtitle**: "SnapClone User" in secondary color

**Stats Section**:
- **Layout**: HStack with 40px spacing
- **Stat Items**: 
  - "42 Snaps" (title2 font, bold numbers)
  - "123 Friends" 
  - "7 Stories"
- **Style**: Centered vertical stacks with caption labels

**Action Buttons**:
- **Settings Button**: 
  - Full width, gray background (.systemGray6)
  - 10px corner radius, standard padding
- **Sign Out Button**:
  - Full width, red background
  - White text, 10px corner radius
  - Calls authViewModel.signOut() with animation

**Layout Spacing**:
- 20px between major sections
- 30px horizontal padding for buttons
- 50px bottom padding

### MCPServerView (Settings)
**Purpose**: MCP server configuration for debugging/development
**Design Specifications**:
- Development-only view for server configuration
- Simple form interface for server settings
- Not visible in production builds

---

## 7. Supporting Views

### PhotoPicker
**Purpose**: System photo library integration
**Design Specifications**:
- **Interface**: UIImagePickerController wrapped in SwiftUI
- **Mode**: Photo selection only (no video)
- **Presentation**: Sheet modal from bottom
- **Selection**: Single photo selection with crop capability

### MCPServerView
**Purpose**: Development server configuration
**Design Specifications**:
- **Visibility**: Development builds only
- **Interface**: Simple settings form
- **Purpose**: MCP (Model Context Protocol) server configuration

---

## Design System Summary

### Color Palette
- **Primary Yellow**: #E6E600 (app branding)
- **Orange Gradient**: #FFB300 (authentication background)
- **Blue Accent**: System blue for secondary actions
- **White**: Primary UI background
- **Black**: Camera interface background
- **Gray Variants**: Secondary text, disabled states, backgrounds

### Typography Hierarchy
- **Large Title**: App names, major headers
- **Title**: Section headers
- **Headline**: Primary content text
- **Body**: Standard content text
- **Caption**: Secondary information, timestamps

### Layout Patterns
- **Full Screen**: Camera views, story viewing
- **Navigation**: Standard iOS navigation with white backgrounds
- **Sheets**: Modal presentations for secondary actions
- **Lists**: Standard iOS list styling with custom row designs
- **Overlay Controls**: Semi-transparent overlays on camera interface

### Interaction Patterns
- **Tap**: Primary actions, navigation
- **Hold**: Video recording (future)
- **Swipe**: Story navigation, dismissal
- **Pull-to-refresh**: Content updates
- **Pinch**: Camera zoom (future)

This specification covers all 14 views in the SnapClone iOS application, providing detailed design requirements for each interface component.