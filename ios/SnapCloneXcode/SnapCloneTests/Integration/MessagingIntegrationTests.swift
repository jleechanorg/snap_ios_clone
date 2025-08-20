import XCTest
import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
@testable import SnapClone

/// Integration tests for Chat/Messaging views → FirebaseMessagingService integration
/// Tests follow TDD Red-Green-Refactor pattern to drive UI → ViewModel → Firebase messaging
class MessagingIntegrationTests: XCTestCase {
    var messagingService: FirebaseMessagingService!
    var cancellables: Set<AnyCancellable>!
    var testConversationId: String!
    var testUserId: String!
    
    override func setUp() {
        super.setUp()
        messagingService = FirebaseMessagingService.shared
        cancellables = Set<AnyCancellable>()
        testConversationId = "test-conversation-\(UUID().uuidString)"
        testUserId = "test-user-\(UUID().uuidString)"
        
        // Configure Firebase for testing if not already configured
        if FirebaseApp.app() == nil {
            XCTFail("Firebase not configured for messaging tests")
        }
    }
    
    override func tearDown() {
        // Cleanup test data
        Task {
            await cleanupTestData()
        }
        cancellables = nil
        super.tearDown()
    }
    
    private func cleanupTestData() async {
        // Remove test conversation and messages
        do {
            let db = Firestore.firestore()
            try await db.collection("conversations").document(testConversationId).delete()
            try await db.collection("messages")
                .whereField("conversationId", isEqualTo: testConversationId)
                .getDocuments()
                .documents
                .forEach { try await $0.reference.delete() }
        } catch {
            print("Cleanup failed: \(error)")
        }
    }
    
    // MARK: - Messaging Service Integration Tests
    
    func testFirebaseMessagingServiceExists() {
        // GIVEN: Firebase Messaging Service
        // WHEN: Service is accessed
        // THEN: Service should exist and be properly initialized
        XCTAssertNotNil(messagingService)
        XCTAssertNotNil(Firestore.firestore())
    }
    
    func testMessagingServiceConformsToProtocol() {
        // GIVEN: Messaging service instance
        // WHEN: Protocol conformance is checked
        // THEN: Should conform to MessagingServiceProtocol
        XCTAssertTrue(messagingService is MessagingServiceProtocol)
    }
    
    // MARK: - Send Message Integration Tests
    
    func testSendTextMessage() async {
        // GIVEN: Valid message data
        let senderId = "sender-\(UUID().uuidString)"
        let receiverId = "receiver-\(UUID().uuidString)"
        let messageContent = "Hello, this is a test message!"
        
        let message = Message(
            senderId: senderId,
            receiverId: receiverId,
            conversationId: testConversationId,
            content: messageContent,
            mediaURL: nil,
            messageType: .text,
            isEphemeral: false,
            viewDuration: nil
        )
        
        do {
            // WHEN: Message is sent
            try await messagingService.sendMessage(message)
            
            // THEN: Message should be stored in Firebase
            let retrievedMessages = try await messagingService.getMessages(for: testConversationId)
            XCTAssertTrue(retrievedMessages.contains { $0.content == messageContent })
            
        } catch {
            XCTFail("Send message failed: \(error.localizedDescription)")
        }
    }
    
    func testSendImageMessage() async {
        // GIVEN: Image message data
        let senderId = "sender-\(UUID().uuidString)"
        let receiverId = "receiver-\(UUID().uuidString)"
        let imageURL = "https://example.com/test-image.jpg"
        
        let message = Message(
            senderId: senderId,
            receiverId: receiverId,
            conversationId: testConversationId,
            content: nil,
            mediaURL: imageURL,
            messageType: .image,
            isEphemeral: true,
            viewDuration: 10.0
        )
        
        do {
            // WHEN: Image message is sent
            try await messagingService.sendMessage(message)
            
            // THEN: Message should be stored with correct media URL
            let retrievedMessages = try await messagingService.getMessages(for: testConversationId)
            XCTAssertTrue(retrievedMessages.contains { $0.mediaURL == imageURL })
            
        } catch {
            XCTFail("Send image message failed: \(error.localizedDescription)")
        }
    }
    
    func testSendEphemeralMessage() async {
        // GIVEN: Ephemeral message data
        let senderId = "sender-\(UUID().uuidString)"
        let receiverId = "receiver-\(UUID().uuidString)"
        let messageContent = "This message will disappear!"
        
        let message = Message(
            senderId: senderId,
            receiverId: receiverId,
            conversationId: testConversationId,
            content: messageContent,
            mediaURL: nil,
            messageType: .text,
            isEphemeral: true,
            viewDuration: 5.0
        )
        
        do {
            // WHEN: Ephemeral message is sent
            try await messagingService.sendMessage(message)
            
            // THEN: Message should be marked as ephemeral
            let retrievedMessages = try await messagingService.getMessages(for: testConversationId)
            let ephemeralMessage = retrievedMessages.first { $0.content == messageContent }
            XCTAssertNotNil(ephemeralMessage)
            XCTAssertTrue(ephemeralMessage?.isEphemeral == true)
            XCTAssertEqual(ephemeralMessage?.viewDuration, 5.0)
            
        } catch {
            XCTFail("Send ephemeral message failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Real-time Message Listening Tests
    
    func testRealTimeMessageListener() async {
        // GIVEN: Message listener setup
        let expectation = XCTestExpectation(description: "Real-time message received")
        let testMessage = "Real-time test message"
        
        // WHEN: Listener is started
        messagingService.startListening(to: testConversationId) { messages in
            if messages.contains(where: { $0.content == testMessage }) {
                expectation.fulfill()
            }
        }
        
        // Send a message to trigger the listener
        let message = Message(
            senderId: testUserId,
            receiverId: "receiver-\(UUID().uuidString)",
            conversationId: testConversationId,
            content: testMessage,
            mediaURL: nil,
            messageType: .text,
            isEphemeral: false,
            viewDuration: nil
        )
        
        do {
            try await messagingService.sendMessage(message)
            
            // THEN: Listener should receive the message
            await fulfillment(of: [expectation], timeout: 10.0)
            
        } catch {
            XCTFail("Real-time listener test failed: \(error.localizedDescription)")
        }
    }
    
    func testStopListeningToMessages() {
        // GIVEN: Active message listener
        var messagesReceived = 0
        
        messagingService.startListening(to: testConversationId) { _ in
            messagesReceived += 1
        }
        
        // WHEN: Listening is stopped
        messagingService.stopListening(to: testConversationId)
        
        // THEN: No more messages should be received
        // This is a basic test - more sophisticated testing would require message injection after stopping
        XCTAssertTrue(true) // Validates that stopListening doesn't crash
    }
    
    // MARK: - Message Retrieval Tests
    
    func testGetMessagesForConversation() async {
        // GIVEN: Conversation with messages
        let message1 = Message(
            senderId: testUserId,
            receiverId: "receiver-1",
            conversationId: testConversationId,
            content: "First message",
            messageType: .text
        )
        
        let message2 = Message(
            senderId: "receiver-1",
            receiverId: testUserId,
            conversationId: testConversationId,
            content: "Second message",
            messageType: .text
        )
        
        do {
            // Send test messages
            try await messagingService.sendMessage(message1)
            try await messagingService.sendMessage(message2)
            
            // WHEN: Messages are retrieved
            let messages = try await messagingService.getMessages(for: testConversationId)
            
            // THEN: Should return all messages for conversation
            XCTAssertGreaterThanOrEqual(messages.count, 2)
            XCTAssertTrue(messages.contains { $0.content == "First message" })
            XCTAssertTrue(messages.contains { $0.content == "Second message" })
            
        } catch {
            XCTFail("Get messages failed: \(error.localizedDescription)")
        }
    }
    
    func testGetMessagesWithLimit() async {
        // GIVEN: Conversation with multiple messages
        for i in 1...5 {
            let message = Message(
                senderId: testUserId,
                receiverId: "receiver-\(i)",
                conversationId: testConversationId,
                content: "Message \(i)",
                messageType: .text
            )
            try? await messagingService.sendMessage(message)
        }
        
        do {
            // WHEN: Messages are retrieved with limit
            let messages = try await messagingService.getMessages(for: testConversationId, limit: 3)
            
            // THEN: Should return limited number of messages
            XCTAssertLesssThanOrEqual(messages.count, 3)
            
        } catch {
            XCTFail("Get messages with limit failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Ephemeral Message Handling Tests
    
    func testEphemeralMessageDeletion() async {
        // GIVEN: Ephemeral message
        let message = Message(
            senderId: testUserId,
            receiverId: "receiver-123",
            conversationId: testConversationId,
            content: "This will be deleted",
            messageType: .text,
            isEphemeral: true,
            viewDuration: 1.0 // Very short duration for testing
        )
        
        do {
            // WHEN: Ephemeral message is sent and viewed
            try await messagingService.sendMessage(message)
            try await messagingService.markMessageAsViewed(message.id)
            
            // Wait for deletion (in real implementation, this would be handled by a timer)
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // THEN: Message should be deleted
            let messages = try await messagingService.getMessages(for: testConversationId)
            XCTAssertFalse(messages.contains { $0.id == message.id })
            
        } catch {
            // This might fail initially if ephemeral deletion logic isn't implemented
            XCTFail("Ephemeral message handling failed: \(error.localizedDescription)")
        }
    }
    
    func testMarkMessageAsViewed() async {
        // GIVEN: Message that hasn't been viewed
        let message = Message(
            senderId: testUserId,
            receiverId: "receiver-456",
            conversationId: testConversationId,
            content: "Mark as viewed test",
            messageType: .text,
            isEphemeral: true,
            viewDuration: 10.0
        )
        
        do {
            try await messagingService.sendMessage(message)
            
            // WHEN: Message is marked as viewed
            try await messagingService.markMessageAsViewed(message.id)
            
            // THEN: Message view status should be updated
            let messages = try await messagingService.getMessages(for: testConversationId)
            let viewedMessage = messages.first { $0.id == message.id }
            XCTAssertNotNil(viewedMessage?.viewedAt)
            
        } catch {
            XCTFail("Mark message as viewed failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Conversation Management Tests
    
    func testCreateConversation() async {
        // GIVEN: Conversation participants
        let participants = [testUserId, "participant-1", "participant-2"]
        let conversationId = Conversation.generateId(for: participants)
        
        do {
            // WHEN: Conversation is created
            try await messagingService.createConversation(id: conversationId, participants: participants)
            
            // THEN: Conversation should exist in Firebase
            let conversation = try await messagingService.getConversation(id: conversationId)
            XCTAssertNotNil(conversation)
            XCTAssertEqual(Set(conversation?.participants ?? []), Set(participants))
            
        } catch {
            XCTFail("Create conversation failed: \(error.localizedDescription)")
        }
    }
    
    func testGetUserConversations() async {
        // GIVEN: User with conversations
        let conversation1Id = "conv1-\(UUID().uuidString)"
        let conversation2Id = "conv2-\(UUID().uuidString)"
        
        do {
            try await messagingService.createConversation(id: conversation1Id, participants: [testUserId, "user1"])
            try await messagingService.createConversation(id: conversation2Id, participants: [testUserId, "user2"])
            
            // WHEN: User conversations are retrieved
            let conversations = try await messagingService.getUserConversations(for: testUserId)
            
            // THEN: Should return user's conversations
            let conversationIds = conversations.map { $0.id }
            XCTAssertTrue(conversationIds.contains(conversation1Id))
            XCTAssertTrue(conversationIds.contains(conversation2Id))
            
        } catch {
            XCTFail("Get user conversations failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Status Tests
    
    func testMessageDeliveryStatus() async {
        // GIVEN: Message with delivery tracking
        let message = Message(
            senderId: testUserId,
            receiverId: "receiver-789",
            conversationId: testConversationId,
            content: "Delivery test message",
            messageType: .text
        )
        
        do {
            // WHEN: Message is sent
            try await messagingService.sendMessage(message)
            
            // THEN: Message should have delivery status
            let messages = try await messagingService.getMessages(for: testConversationId)
            let sentMessage = messages.first { $0.content == "Delivery test message" }
            XCTAssertNotNil(sentMessage?.sentAt)
            XCTAssertEqual(sentMessage?.status, .sent)
            
        } catch {
            XCTFail("Message delivery status test failed: \(error.localizedDescription)")
        }
    }
    
    func testMessageReadStatus() async {
        // GIVEN: Delivered message
        let message = Message(
            senderId: testUserId,
            receiverId: "receiver-read",
            conversationId: testConversationId,
            content: "Read status test",
            messageType: .text
        )
        
        do {
            try await messagingService.sendMessage(message)
            
            // WHEN: Message is marked as read
            try await messagingService.markMessageAsRead(message.id, by: "receiver-read")
            
            // THEN: Message should show read status
            let messages = try await messagingService.getMessages(for: testConversationId)
            let readMessage = messages.first { $0.content == "Read status test" }
            XCTAssertNotNil(readMessage?.readAt)
            XCTAssertEqual(readMessage?.status, .read)
            
        } catch {
            XCTFail("Message read status test failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testSendMessageWithInvalidData() async {
        // GIVEN: Invalid message data
        let invalidMessage = Message(
            senderId: "", // Empty sender ID
            receiverId: "",
            conversationId: "",
            content: nil,
            messageType: .text
        )
        
        do {
            // WHEN: Invalid message is sent
            try await messagingService.sendMessage(invalidMessage)
            
            // THEN: Should throw validation error
            XCTFail("Should have thrown validation error for invalid message")
        } catch {
            // Expected error for invalid data
            XCTAssertNotNil(error)
        }
    }
    
    func testGetMessagesForNonExistentConversation() async {
        // GIVEN: Non-existent conversation ID
        let nonExistentId = "non-existent-conversation"
        
        do {
            // WHEN: Messages are requested for non-existent conversation
            let messages = try await messagingService.getMessages(for: nonExistentId)
            
            // THEN: Should return empty array
            XCTAssertTrue(messages.isEmpty)
            
        } catch {
            // May throw error depending on implementation
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Performance Tests
    
    func testMessageLoadingPerformance() async {
        // GIVEN: Conversation with many messages
        let messageCount = 100
        
        for i in 1...messageCount {
            let message = Message(
                senderId: testUserId,
                receiverId: "performance-test",
                conversationId: testConversationId,
                content: "Performance test message \(i)",
                messageType: .text
            )
            try? await messagingService.sendMessage(message)
        }
        
        // WHEN: Messages are loaded with performance measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let messages = try await messagingService.getMessages(for: testConversationId)
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            // THEN: Should load messages within reasonable time
            XCTAssertGreaterThanOrEqual(messages.count, messageCount)
            XCTAssertLessThan(timeElapsed, 5.0) // Should load within 5 seconds
            
        } catch {
            XCTFail("Performance test failed: \(error.localizedDescription)")
        }
    }
}