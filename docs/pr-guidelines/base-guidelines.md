# Base Guidelines - iOS Snapchat Clone Development

**Purpose**: Canonical protocols and anti-patterns for all iOS development work
**Created**: 2025-01-19
**Last Updated**: 2025-01-19

## 🎯 Core Principles

### Architecture-First Development
- **Lead with architectural thinking, follow with tactical execution**
- **Verify integration before claiming sophistication**
- **Test data flow from Firebase → Services → ViewModels → UI**
- **One well-designed solution that enables many downstream successes**

### Integration Reality Verification
- **UI components MUST use their corresponding ViewModels**
- **Services MUST be actually called by the UI/ViewModels**
- **Data flow MUST be traceable end-to-end**
- **Functionality testing MUST verify actual operations, not just UI appearance**

## 🚫 Critical Anti-Patterns

### Architecture Disconnection Pattern
**SYMPTOM**: Sophisticated backend code exists but UI uses placeholder/static content
**DETECTION**: 
- UI components missing @StateObject/@ObservedObject ViewModel bindings
- Button actions with empty blocks: `Button("Action") { }`
- Static text where dynamic data should exist
- No imports of sophisticated ViewModels in UI files

**PREVENTION**: Always verify ViewModels are instantiated and used by UI

### Assumption-Based Testing Pattern
**SYMPTOM**: Claiming sophistication based on file existence rather than integration
**DETECTION**:
- Testing UI navigation without testing underlying functionality
- Assuming build success means feature integration
- Claiming "sophisticated implementation" without functional verification

**PREVENTION**: Follow Architecture Verification Protocol (below)

### Mock-to-Production Confusion Pattern
**SYMPTOM**: Placeholder/mock components presented as production features
**DETECTION**:
- Hardcoded data in "production" features
- Static UI elements instead of dynamic Firebase-driven content
- Test/mock services still in use for production claims

**PREVENTION**: Systematic integration verification before any sophistication claims

## 📋 Architecture Verification Protocol

**MANDATORY BEFORE claiming "sophisticated features":**

### Phase 1: Integration Reality Check
1. **UI File Review**: Read main UI components (MainAppView, CameraView, etc.)
2. **ViewModel Binding Verification**: Check for @StateObject/@ObservedObject declarations
3. **Action Implementation Check**: Verify button actions call actual ViewModel methods
4. **Import Analysis**: Confirm sophisticated services/ViewModels are imported and used

### Phase 2: Data Flow Verification
1. **Firebase → Services**: Verify Firebase services are configured and accessible
2. **Services → ViewModels**: Check that ViewModels use injected services
3. **ViewModels → UI**: Confirm UI components bind to ViewModel @Published properties
4. **End-to-End Trace**: Follow one complete data flow (e.g., user action → Firebase → UI update)

### Phase 3: Functional Testing
1. **Real Operation Test**: Test ONE actual function (camera capture, message send, etc.)
2. **Firebase Integration Test**: Verify actual Firebase operations occur
3. **Error Handling Test**: Confirm error states are properly handled
4. **Permission Verification**: Test device permission flows work correctly

## 🔧 Tool Selection Hierarchy

### Preferred Tool Order
1. **Serena MCP**: For complex code analysis, symbol finding, architectural understanding
2. **Read Tool**: For specific file examination when path is known
3. **Bash Commands**: For build operations, git operations, system interactions

### When NOT to Use Serena MCP
- Simple file reading when exact path is known
- Git operations
- Build/test execution
- Basic file system operations

## 📈 Quality Standards

### Evidence-Based Development
- **Claims require evidence**: Never claim sophistication without demonstrating integration
- **Show, don't tell**: Demonstrate functionality through testing, not code existence
- **Verify assumptions**: Always check that assumed integrations actually exist

### Systematic Change Management
- **Architecture verification before UI changes**
- **Integration testing before feature claims**
- **End-to-end validation before completion**

### Resource Optimization
- **Use appropriate tools for each task**
- **Minimize redundant file operations**
- **Efficient context usage through targeted analysis**

## 🚨 Red Flags Checklist

**Immediately investigate if you see:**
- [ ] Static text in "sophisticated" UI (Text("👻") instead of dynamic content)
- [ ] UI components not importing their ViewModels
- [ ] Empty action blocks in buttons
- [ ] No @StateObject/@ObservedObject bindings to sophisticated ViewModels
- [ ] Services existing in files but never called by UI
- [ ] Mock/placeholder data in "production" features
- [ ] Build success without functional verification
- [ ] UI navigation testing without backend functionality testing

## 📚 Integration Verification Questions

**Always ask before claiming sophistication:**
1. "Does this UI component actually USE its sophisticated ViewModel?"
2. "Are the button actions calling real methods with real consequences?"
3. "Is data flowing from Firebase through Services to ViewModels to UI?"
4. "Can I trace one complete user action from UI tap to Firebase operation?"
5. "Have I tested actual functionality, not just UI appearance?"

---

**Implementation Note**: These guidelines prevent the costly mistake of testing placeholder UI while sophisticated backend code exists unused. Always verify integration before claiming sophistication.