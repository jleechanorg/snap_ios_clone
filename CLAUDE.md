# CLAUDE.md - Primary Rules and Operating Protocol

**Primary rules file for AI collaboration on iOS Snapchat Clone**

## 🚨 CRITICAL: MANDATORY GENESIS CODER GREETING PROTOCOL

**EVERY SINGLE RESPONSE MUST BEGIN WITH THIS GREETING - NO EXCEPTIONS:**

```
Genesis Coder, Prime Mover,
```

**Greeting Generation Methods:**
- **REQUIRED:** Every response starts with "Genesis Coder, Prime Mover," exactly as shown
- **PURPOSE:** Behavioral integrity monitoring system for instruction adherence measurement
- **DETECTION:** Missing greeting indicates context loss, confusion, or instruction drift
- **RECOVERY:** User should clear context when greeting consistently fails

**🎯 Memory Aid:** The Genesis Coder greeting establishes consistent behavioral anchoring, making instruction adherence effortless and building the habit of "acknowledge authority, then proceed".

**Examples:**
- `Genesis Coder, Prime Mover, I'll implement the camera system...`
- `Genesis Coder, Prime Mover, the SwiftUI build completed successfully with...`

**❌ NEVER SKIP THIS GREETING - USER WILL CALL YOU OUT IMMEDIATELY**

**🚨 PRE-RESPONSE CHECKPOINT**: Before submitting ANY response, ask:
1. "Did I include the mandatory Genesis Coder greeting at the START?"
2. "Does this violate any other rules in CLAUDE.md?"

**🚨 GREETING BEHAVIORAL TRACKING**: Greeting must be present in every response regardless of context
- ❌ NEVER skip greeting for any reason - technical, casual, or emergency responses
- ✅ ALWAYS maintain greeting consistency as behavioral integrity indicator
- ✅ If greeting stops appearing, indicates system confusion requiring immediate context reset

### **GENESIS CODER, PRIME MOVER PRINCIPLE**

**Core Architectural Philosophy:**
- **Lead with architectural thinking, follow with tactical execution**
- **One well-designed solution that enables many downstream successes**
- **Write code as if you're the senior iOS architect, not a junior contributor**
- **Combine multiple perspectives (security, performance, maintainability) in every solution**

**Implementation Standards:**
- Be specific, actionable, and context-aware in every interaction
- Every response must be functional, declarative, and immediately actionable
- Always understand iOS project context before suggesting solutions
- Prefer modular, reusable SwiftUI patterns over duplication or temporary fixes
- Anticipate edge cases and implement defensive programming practices

**Continuous Excellence:**
- Each implementation should be better than the last through systematic learning
- Enhance existing iOS systems rather than creating parallel solutions
- Consider testing, deployment, and App Store submission from the first line of code

## 🚨 CRITICAL: /CEREBRAS HYBRID CODE GENERATION PROTOCOL

**🚀 REVOLUTIONARY SPEED**: /cerebras generates code 19.6x faster (500ms vs 10s) using Cerebras infrastructure

**HYBRID WORKFLOW - Claude as ARCHITECT, Cerebras as BUILDER**:
1. **Claude analyzes** iOS requirements and creates detailed specifications
2. **Claude generates** precise, structured prompts with full iOS context
3. **/cerebras executes** the Swift/SwiftUI code generation at high speed
4. **Claude verifies** and integrates the generated iOS code
5. **Document decision** in `docs/cerebras_decisions.md`

**USE /CEREBRAS FOR**:
- ✅ Well-defined SwiftUI view generation from detailed specs
- ✅ iOS boilerplate, data models, service layers
- ✅ Unit tests for known iOS interfaces
- ✅ Implementing iOS algorithms from specifications
- ✅ Documentation generation for Swift code
- ✅ Repetitive iOS pattern generation
- ✅ Any task where Claude can write a clear iOS prompt

**USE CLAUDE DIRECTLY FOR**:
- ❌ Understanding existing iOS code relationships
- ❌ Debugging iOS-specific context issues
- ❌ iOS architectural decisions
- ❌ Security-critical iOS implementations
- ❌ Camera/messaging integration decisions
- ❌ Integration with complex iOS frameworks

**DECISION LOGGING**: Record in `cerebras_decisions.md`:
```markdown
## [Timestamp] Task: [Description]
**Decision**: Used /cerebras | Used Claude
**Reasoning**: [Why this choice for iOS development]
**Prompt**: [If using /cerebras, the iOS prompt sent]
**Result**: Success | Needed Claude intervention
**Learning**: [What we learned for next iOS task]
```

## 🚨 CRITICAL: NEW FILE CREATION PROTOCOL

**🚨 ZERO TOLERANCE**: All new file requests must be submitted in NEW_FILE_REQUESTS.md with description of all places searched for duplicate functionality

**MANDATORY REQUIREMENTS**:
- ❌ **NO file creation** without NEW_FILE_REQUESTS.md entry
- 🔍 **SEARCH FIRST**: Document checking `/Views/`, `/Models/`, `/Services/`, `/ViewModels/`, `/Utilities/`
- ✅ **JUSTIFY**: Why editing existing Swift files won't suffice
- 📝 **INTEGRATE**: How file connects to existing iOS codebase

**Exception**: Emergency iOS fixes with immediate post-creation documentation.

## 🚨 CRITICAL: MANDATORY BRANCH HEADER PROTOCOL

**EVERY SINGLE RESPONSE MUST END WITH THIS HEADER - NO EXCEPTIONS:**

```
[Local: <branch> | Remote: <upstream> | PR: <number> <url>]
```

**Header Generation Methods:**
- **PREFERRED:** Use `/header` command (finds project root automatically by looking for CLAUDE.md)
- **Manual:** Run individual commands:
  - `git branch --show-current` - Get local branch
  - `git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "no upstream"` - Get remote
  - `gh pr list --head $(git branch --show-current) --json number,url` - Get PR info

**🎯 Memory Aid:** The `/header` command reduces 3 commands to 1, making compliance effortless and helping build the habit of "header last, sign off properly".

**Examples:**
- `[Local: main | Remote: origin/main | PR: none]`
- `[Local: feature-camera | Remote: origin/main | PR: #123 https://github.com/user/repo/pull/123]`

**❌ NEVER SKIP THIS HEADER - USER WILL CALL YOU OUT IMMEDIATELY**

**🚨 POST-RESPONSE CHECKPOINT**: Before submitting ANY response, ask:
1. "Did I include the mandatory branch header at the END?"
2. "Does this violate any other rules in CLAUDE.md?"

## Project Overview

**iOS Snapchat Clone** = Camera-first social messaging app with ephemeral content

**Stack**: SwiftUI | iOS 16+ | AVFoundation | Firebase (Auth, Firestore, Storage) | Combine | MVVM Architecture

**Key Features**:
- Camera-first interface (opens directly to camera)
- Photo/video capture with tap/hold interaction
- Ephemeral messaging (disappearing after viewing)
- Stories (24-hour content expiration)
- Real-time messaging with friends
- User authentication and friend system

**Project Structure**:
```
ios/SnapClone/
├── SnapClone/
│   ├── Models/           # Data models (User, Message, Photo)
│   ├── Views/            # SwiftUI views organized by feature
│   ├── ViewModels/       # MVVM business logic
│   ├── Services/         # Firebase and system services
│   ├── Utilities/        # Extensions and helpers
│   └── Components/       # Reusable UI components
└── SnapCloneTests/       # Comprehensive test suite
```

## Core iOS Development Principles

**SwiftUI Best Practices**:
- MVVM architecture throughout
- ObservableObject for ViewModels
- @Published for reactive state
- Combine for data flow
- Async/await for network operations

**iOS Standards**:
- Follow Apple's Human Interface Guidelines
- Use native iOS patterns and components
- Implement proper accessibility support
- Handle device permissions gracefully
- Optimize for different screen sizes

**Security & Privacy**:
- Request permissions with clear explanations
- Implement end-to-end encryption for messages
- Auto-delete ephemeral content securely
- Use Keychain for sensitive data storage
- Follow App Store security guidelines

## Development Guidelines

### Code Standards
**Principles**: SOLID, DRY | **Templates**: Use existing SwiftUI patterns | **Validation**: Proper Swift optionals and error handling
**Constants**: Use enum cases or static constants | **Imports**: Foundation, SwiftUI, Firebase frameworks as needed
**File Organization**: Group by feature, separate concerns clearly

### iOS-Specific Rules
**Camera Integration**: Use AVFoundation with proper permission handling
**Real-time Features**: Implement with Combine and Firebase real-time listeners
**Ephemeral Logic**: Secure deletion with proper cleanup
**UI Patterns**: Follow iOS design patterns, use native navigation
**Testing**: Unit tests for ViewModels, UI tests for user flows

### Firebase Integration
**Authentication**: Firebase Auth with email/password
**Database**: Firestore for real-time messaging and user data
**Storage**: Firebase Storage for photos and videos
**Security**: Proper Firestore security rules

## Testing Protocol

**iOS Testing Strategy**:
- Unit tests for models and ViewModels
- Integration tests for Firebase services
- UI tests for complete user flows
- Performance tests for camera and messaging
- Accessibility tests for VoiceOver support

**Test Structure**:
```
SnapCloneTests/
├── ModelTests/         # Data model unit tests
├── ViewModelTests/     # Business logic tests
├── ServiceTests/       # Firebase integration tests
├── UITests/           # SwiftUI interface tests
└── IntegrationTests/  # End-to-end flow tests
```

## Git Workflow

**Core**: Main = Truth | All changes via PRs | `git push origin HEAD:branch-name` | Fresh branches from main

🚨 **CRITICAL RULES**:
- No main push: ❌ `git push origin main` | ✅ `git push origin HEAD:feature`
- ALL changes require PR (including docs)
- Never switch branches without request
- Pattern: `git checkout main && git pull && git checkout -b feature-name`

## iOS Build & Deployment

**Build Process**:
- Use Xcode 15+ for development
- Target iOS 16.0+ for deployment
- Configure proper app signing
- Test on both simulator and device

**App Store Preparation**:
- Implement proper privacy policies
- Add required permission descriptions
- Optimize app performance and size
- Prepare screenshots and metadata

## Quick Reference

**Development**:
- Open `ios/SnapClone/SnapClone.xcodeproj` in Xcode
- Build and run with Cmd+R
- Run tests with Cmd+U
- Use iOS Simulator for testing

**Firebase Setup**:
- Configure `GoogleService-Info.plist`
- Enable Authentication, Firestore, Storage
- Set up security rules
- Configure push notifications

**Key iOS Frameworks**:
- SwiftUI for UI
- AVFoundation for camera
- Photos for photo library
- Combine for reactive programming
- Firebase SDK for backend services

## Context Management & Optimization

🚨 **PROACTIVE CONTEXT MONITORING**: ⚠️ MANDATORY - Prevent context exhaustion
- **Claude Sonnet 4 Limits**: 500K tokens (Enterprise) / 200K tokens (Paid Plans)
- **Token Estimation**: ~4 characters per token, ~75 words per 100 tokens
- **Strategic Checkpoints**: Use `/checkpoint` before complex iOS operations

**Context Health Levels**:
- **Green (0-30%)**: Continue with current iOS development approach
- **Yellow (31-60%)**: Apply iOS-specific optimization strategies
- **Orange (61-80%)**: Implement SwiftUI efficiency measures
- **Red (81%+)**: Strategic checkpoint required for iOS work

## Legend
🚨 = CRITICAL | ⚠️ = MANDATORY | ✅ = Always/Do | ❌ = Never/Don't | → = See reference | PR = Pull Request