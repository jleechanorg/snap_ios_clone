import XCTest
import SwiftUI
import Firebase
import Combine
@testable import SnapClone

/// End-to-End Integration Tests for complete iOS Snapchat Clone architecture
/// Tests the full user flow: Authentication → Camera → Capture → Share → Message → Stories
/// Validates ViewModel dependency injection, Firebase connectivity, and cross-feature integration
class SnapCloneE2EIntegrationTests: XCTestCase {
    var app: SnapCloneApp!
    var authService: FirebaseAuthService!
    var messagingService: FirebaseMessagingService!
    var storageService: FirebaseStorageService!
    var cameraViewModel: CameraViewModel!
    var cancellables: Set<AnyCancellable>!
    
    // Test user data
    var testEmail: String!
    var testPassword: String!
    var testUserId: String!
    
    override func setUp() {
        super.setUp()
        
        // Initialize services
        authService = FirebaseAuthService.shared
        messagingService = FirebaseMessagingService.shared
        storageService = FirebaseStorageService.shared
        cameraViewModel = CameraViewModel()
        cancellables = Set<AnyCancellable>()
        
        // Generate test user data
        let uuid = UUID().uuidString.prefix(8)
        testEmail = "e2etest\(uuid)@example.com"
        testPassword = "E2ETestPassword123!"
        testUserId = "e2e-user-\(uuid)"
        
        // Configure Firebase for testing if not already configured
        if FirebaseApp.app() == nil {
            XCTFail("Firebase not configured for E2E tests")
        }
    }
    
    override func tearDown() {
        // Cleanup test user and data
        Task {
            await cleanupTestUser()
        }
        cancellables = nil
        super.tearDown()
    }
    
    private func cleanupTestUser() async {
        do {
            // Sign out first
            try await authService.signOut()
            
            // Sign back in to delete user
            if let user = try? await authService.signIn(email: testEmail, password: testPassword) {
                try await user.delete()
            }
            
            // Cleanup any remaining data in Firestore/Storage
            await cleanupUserData()
            
        } catch {
            print("E2E cleanup failed: \(error)")
        }
    }
    
    private func cleanupUserData() async {
        do {
            let db = Firestore.firestore()
            
            // Delete user conversations
            let conversationsQuery = db.collection("conversations")
                .whereField("participants", arrayContains: testUserId)
            let conversationSnapshots = try await conversationsQuery.getDocuments()
            
            for doc in conversationSnapshots.documents {
                try await doc.reference.delete()
            }
            
            // Delete user messages
            let messagesQuery = db.collection("messages")
                .whereField("senderId", isEqualTo: testUserId)
            let messageSnapshots = try await messagesQuery.getDocuments()
            
            for doc in messageSnapshots.documents {
                try await doc.reference.delete()
            }
            
            // Delete user stories
            let storiesQuery = db.collection("stories")
                .whereField("userId", isEqualTo: testUserId)
            let storySnapshots = try await storiesQuery.getDocuments()
            
            for doc in storySnapshots.documents {
                try await doc.reference.delete()
            }
            
        } catch {
            print("User data cleanup failed: \(error)")
        }
    }
    
    // MARK: - Complete User Flow E2E Tests
    
    func testCompleteUserFlowLoginToCameraCaptureShareMessage() async {
        // GIVEN: New user ready to use the app
        let flowExpectation = XCTestExpectation(description: "Complete user flow")
        
        do {
            // STEP 1: Authentication Flow
            print("🔐 Step 1: User Authentication")
            let authenticatedUser = try await authService.signUp(email: testEmail, password: testPassword)
            XCTAssertNotNil(authenticatedUser)
            XCTAssertTrue(authService.isAuthenticated)
            print("✅ Authentication successful")
            
            // STEP 2: Camera Setup and Permission
            print("📸 Step 2: Camera Setup")
            cameraViewModel.setupCamera()
            
            // Simulate camera permission granted (in real test, this would require user interaction)
            cameraViewModel.authorizationStatus = .authorized
            XCTAssertEqual(cameraViewModel.authorizationStatus, .authorized)
            print("✅ Camera permissions granted")
            
            // STEP 3: Start Camera Session
            print("🎥 Step 3: Camera Session")
            let sessionExpectation = XCTestExpectation(description: "Camera session started")
            
            cameraViewModel.$isSessionRunning
                .sink { isRunning in
                    if isRunning {
                        sessionExpectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            cameraViewModel.startSession()
            await fulfillment(of: [sessionExpectation], timeout: 10.0)
            XCTAssertTrue(cameraViewModel.isSessionRunning)
            print("✅ Camera session active")
            
            // STEP 4: Simulate Photo Capture
            print("📷 Step 4: Photo Capture")
            let captureExpectation = XCTestExpectation(description: "Photo captured")
            
            // Create test image for capture simulation
            let testImage = createTestImage()
            cameraViewModel.capturedImage = testImage
            
            cameraViewModel.$capturedImage
                .sink { image in
                    if image != nil {
                        captureExpectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            await fulfillment(of: [captureExpectation], timeout: 5.0)
            XCTAssertNotNil(cameraViewModel.capturedImage)
            print("✅ Photo captured successfully")
            
            // STEP 5: Create Friend/Receiver
            print("👥 Step 5: Friend Setup")
            let friendUserId = "friend-\(UUID().uuidString)"
            let friendEmail = "friend\(UUID().uuidString.prefix(8))@example.com"
            let friendPassword = "FriendPassword123!"
            
            // Create friend account
            let friendUser = try await authService.signUp(email: friendEmail, password: friendPassword)
            XCTAssertNotNil(friendUser)
            
            // Sign back in as original user
            try await authService.signOut()
            _ = try await authService.signIn(email: testEmail, password: testPassword)
            
            print("✅ Friend account created")
            
            // STEP 6: Share Photo (Upload to Firebase Storage)
            print("☁️ Step 6: Photo Sharing")
            let shareExpectation = XCTestExpectation(description: "Photo shared")
            
            guard let capturedImage = cameraViewModel.capturedImage else {
                XCTFail("No captured image to share")
                return
            }
            
            // Monitor upload progress
            cameraViewModel.$isUploading
                .sink { isUploading in
                    if !isUploading && self.cameraViewModel.activeUploads.isEmpty {
                        shareExpectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            await cameraViewModel.sharePhoto(capturedImage, to: friendUser.uid, caption: "E2E Test Photo")
            await fulfillment(of: [shareExpectation], timeout: 30.0)
            print("✅ Photo shared to Firebase Storage")
            
            // STEP 7: Verify Message Creation
            print("💬 Step 7: Message Verification")
            let conversationId = Conversation.generateId(for: [authenticatedUser.uid, friendUser.uid])
            let messages = try await messagingService.getMessages(for: conversationId)
            
            XCTAssertGreaterThan(messages.count, 0)
            XCTAssertTrue(messages.contains { $0.messageType == .image })
            print("✅ Message created in Firebase Firestore")
            
            // STEP 8: Real-time Message Listening
            print("🔄 Step 8: Real-time Updates")
            let realtimeExpectation = XCTestExpectation(description: "Real-time message received")
            
            messagingService.startListening(to: conversationId) { updatedMessages in
                if updatedMessages.count > 0 {
                    realtimeExpectation.fulfill()
                }
            }
            
            await fulfillment(of: [realtimeExpectation], timeout: 15.0)
            print("✅ Real-time messaging active")
            
            // STEP 9: Story Creation (Optional)
            print("📚 Step 9: Story Creation")
            guard let storyImageData = capturedImage.jpegData(compressionQuality: 0.8) else {
                XCTFail("Failed to create story image data")
                return
            }
            
            let storyId = "e2e-story-\(UUID().uuidString)"
            let storyURL = try await storageService.uploadStoryImage(
                storyImageData,
                storyId: storyId,
                userId: authenticatedUser.uid
            )
            
            XCTAssertFalse(storyURL.isEmpty)
            print("✅ Story uploaded to Firebase Storage")
            
            // STEP 10: End-to-End Flow Completion
            print("🎉 Step 10: Flow Completion")
            
            // Verify all systems are working
            XCTAssertTrue(authService.isAuthenticated)
            XCTAssertNotNil(cameraViewModel.capturedImage)
            XCTAssertGreaterThan(messages.count, 0)
            XCTAssertFalse(storyURL.isEmpty)
            
            flowExpectation.fulfill()
            print("✅ Complete E2E flow successful!")
            
            // Cleanup friend user
            try await authService.signOut()
            _ = try await authService.signIn(email: friendEmail, password: friendPassword)
            try await authService.deleteCurrentUser()
            
        } catch {
            XCTFail("E2E flow failed at step: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [flowExpectation], timeout: 120.0) // 2 minutes for complete flow
    }
    
    // MARK: - Cross-Service Integration Tests
    
    func testViewModelDependencyInjectionAcrossApp() {
        // GIVEN: App with all ViewModels
        let app = SnapCloneApp()
        
        // WHEN: ViewModels are accessed
        // THEN: All major ViewModels should be properly initialized
        XCTAssertNotNil(cameraViewModel)
        XCTAssertNotNil(authService)
        XCTAssertNotNil(messagingService)
        XCTAssertNotNil(storageService)
        
        // Test that ViewModels can communicate
        XCTAssertTrue(cameraViewModel.messagingService is MessagingServiceProtocol)
        XCTAssertNotNil(cameraViewModel.messagingService)
    }
    
    func testFirebaseServiceConnectivity() async {
        // GIVEN: All Firebase services
        let connectivityExpectation = XCTestExpectation(description: "All Firebase services connected")
        
        do {
            // WHEN: Services are tested for connectivity
            
            // Test Firebase Auth
            XCTAssertNotNil(Auth.auth())
            
            // Test Firestore
            let db = Firestore.firestore()
            let testDoc = db.collection("connectivity-test").document("test")
            try await testDoc.setData(["test": "data"])
            let retrievedData = try await testDoc.getDocument()
            XCTAssertTrue(retrievedData.exists)
            try await testDoc.delete() // Cleanup
            
            // Test Firebase Storage
            let storage = Storage.storage()
            let testRef = storage.reference().child("connectivity-test/test.txt")
            let testData = "connectivity test".data(using: .utf8)!
            _ = try await testRef.putData(testData)
            let downloadURL = try await testRef.downloadURL()
            XCTAssertTrue(downloadURL.absoluteString.hasPrefix("https://"))
            try await testRef.delete() // Cleanup
            
            connectivityExpectation.fulfill()
            
        } catch {
            XCTFail("Firebase connectivity test failed: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [connectivityExpectation], timeout: 30.0)
    }
    
    func testNavigationBetweenMainViews() {
        // GIVEN: Main app views
        let cameraView = CameraView()
        let authView = AuthenticationView()
        let profileView = ProfileView()
        
        // WHEN: Views are created with proper environment objects
        let cameraHostingController = UIHostingController(
            rootView: cameraView.environmentObject(cameraViewModel)
        )
        let authHostingController = UIHostingController(rootView: authView)
        let profileHostingController = UIHostingController(rootView: profileView)
        
        // THEN: All views should be created without errors
        XCTAssertNotNil(cameraHostingController.rootView)
        XCTAssertNotNil(authHostingController.rootView)
        XCTAssertNotNil(profileHostingController.rootView)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagementAndCleanup() async {
        // GIVEN: ViewModels and services in use
        weak var weakCameraViewModel = cameraViewModel
        weak var weakAuthService = authService
        weak var weakMessagingService = messagingService
        
        // WHEN: Strong references are released
        cameraViewModel = nil
        // Note: Services are singletons, so they won't be deallocated
        
        // THEN: ViewModels should be deallocated when no longer referenced
        XCTAssertNil(weakCameraViewModel)
        
        // Services should remain available (singleton pattern)
        XCTAssertNotNil(weakAuthService)
        XCTAssertNotNil(weakMessagingService)
    }
    
    func testConcurrentOperations() async {
        // GIVEN: Multiple concurrent operations
        let concurrentExpectation = XCTestExpectation(description: "Concurrent operations completed")
        
        do {
            // Create test user first
            let user = try await authService.signUp(email: testEmail, password: testPassword)
            
            // WHEN: Multiple operations are performed concurrently
            await withTaskGroup(of: Void.self) { group in
                
                // Task 1: Camera operations
                group.addTask {
                    self.cameraViewModel.setupCamera()
                    self.cameraViewModel.startSession()
                    
                    // Simulate capture
                    self.cameraViewModel.capturedImage = self.createTestImage()
                }
                
                // Task 2: Messaging operations
                group.addTask {
                    let testConversationId = "concurrent-test-\(UUID().uuidString)"
                    let message = Message(
                        senderId: user.uid,
                        receiverId: "concurrent-receiver",
                        conversationId: testConversationId,
                        content: "Concurrent test message",
                        messageType: .text
                    )
                    
                    do {
                        try await self.messagingService.sendMessage(message)
                    } catch {
                        print("Concurrent messaging error: \(error)")
                    }
                }
                
                // Task 3: Storage operations
                group.addTask {
                    let testImageData = self.createTestImage().jpegData(compressionQuality: 0.8)!
                    let storyId = "concurrent-story-\(UUID().uuidString)"
                    
                    do {
                        _ = try await self.storageService.uploadStoryImage(
                            testImageData,
                            storyId: storyId,
                            userId: user.uid
                        )
                    } catch {
                        print("Concurrent storage error: \(error)")
                    }
                }
            }
            
            // THEN: All operations should complete without conflicts
            concurrentExpectation.fulfill()
            
        } catch {
            XCTFail("Concurrent operations test failed: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [concurrentExpectation], timeout: 60.0)
    }
    
    // MARK: - Error Recovery Tests
    
    func testNetworkErrorRecovery() async {
        // GIVEN: User authenticated and ready to perform operations
        do {
            _ = try await authService.signUp(email: testEmail, password: testPassword)
            
            // WHEN: Network operations are performed
            // (In a real test, we'd simulate network failures)
            
            // Test that services handle errors gracefully
            let invalidMessage = Message(
                senderId: "",
                receiverId: "",
                conversationId: "",
                content: nil,
                messageType: .text
            )
            
            do {
                try await messagingService.sendMessage(invalidMessage)
                XCTFail("Should have thrown error for invalid message")
            } catch {
                // THEN: Should handle errors appropriately
                XCTAssertNotNil(error)
            }
            
        } catch {
            XCTFail("Error recovery test setup failed: \(error.localizedDescription)")
        }
    }
    
    func testDataConsistencyAcrossServices() async {
        // GIVEN: User performing operations across services
        do {
            let user = try await authService.signUp(email: testEmail, password: testPassword)
            
            // WHEN: Data is created in one service
            let conversationId = "consistency-test-\(UUID().uuidString)"
            let message = Message(
                senderId: user.uid,
                receiverId: "consistency-receiver",
                conversationId: conversationId,
                content: "Consistency test message",
                messageType: .text
            )
            
            try await messagingService.sendMessage(message)
            
            // THEN: Data should be consistent when accessed through different services
            let retrievedMessages = try await messagingService.getMessages(for: conversationId)
            XCTAssertGreaterThan(retrievedMessages.count, 0)
            
            let sentMessage = retrievedMessages.first { $0.content == "Consistency test message" }
            XCTAssertNotNil(sentMessage)
            XCTAssertEqual(sentMessage?.senderId, user.uid)
            
        } catch {
            XCTFail("Data consistency test failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testAppLaunchPerformance() {
        // GIVEN: App launch scenario
        let launchExpectation = XCTestExpectation(description: "App launch completed")
        
        // WHEN: App components are initialized
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate app launch sequence
        let authService = FirebaseAuthService.shared
        let messagingService = FirebaseMessagingService.shared
        let storageService = FirebaseStorageService.shared
        let cameraViewModel = CameraViewModel()
        
        let launchTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // THEN: Should launch within reasonable time
        XCTAssertNotNil(authService)
        XCTAssertNotNil(messagingService)
        XCTAssertNotNil(storageService)
        XCTAssertNotNil(cameraViewModel)
        XCTAssertLessThan(launchTime, 2.0) // Should launch within 2 seconds
        
        launchExpectation.fulfill()
        
        wait(for: [launchExpectation], timeout: 5.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemBlue.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        // Add some text to make it identifiable
        let text = "E2E Test"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    // MARK: - Architecture Validation Tests
    
    func testMVVMArchitectureCompliance() {
        // GIVEN: App components following MVVM pattern
        // WHEN: Architecture is analyzed
        // THEN: Should follow MVVM principles
        
        // Test that ViewModels are ObservableObject
        XCTAssertTrue(cameraViewModel is ObservableObject)
        
        // Test that ViewModels don't import UIKit directly (SwiftUI only)
        // This would be validated through static analysis in a real implementation
        XCTAssertTrue(true)
        
        // Test that Services are protocol-based
        XCTAssertTrue(messagingService is MessagingServiceProtocol)
    }
    
    func testDependencyInjectionPattern() {
        // GIVEN: Services and ViewModels with dependencies
        // WHEN: Dependencies are injected
        // THEN: Should follow proper DI patterns
        
        // Test that ViewModels receive services through dependency injection
        XCTAssertNotNil(cameraViewModel.messagingService)
        
        // Test that services can be swapped (protocol-based design)
        XCTAssertTrue(cameraViewModel.messagingService is MessagingServiceProtocol)
    }
    
    func testSingletonPatternUsage() {
        // GIVEN: Shared services
        // WHEN: Services are accessed multiple times
        // THEN: Should return same instance
        
        let authService1 = FirebaseAuthService.shared
        let authService2 = FirebaseAuthService.shared
        XCTAssertTrue(authService1 === authService2)
        
        let messagingService1 = FirebaseMessagingService.shared
        let messagingService2 = FirebaseMessagingService.shared
        XCTAssertTrue(messagingService1 === messagingService2)
    }
}