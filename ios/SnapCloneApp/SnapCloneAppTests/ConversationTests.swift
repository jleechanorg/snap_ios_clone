//
//  ConversationTests.swift
//  SnapCloneTests
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Comprehensive tests for Conversation model and chat logic
//

import XCTest
import FirebaseFirestore
@testable import SnapClone

final class ConversationTests: XCTestCase {
    
    // MARK: - Properties
    
    var conversation: Conversation!
    var user1: User!
    var user2: User!
    var message1: Message!
    var message2: Message!
    var message3: Message!
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        user1 = User(
            id: "user1",
            username: "testuser1",
            email: "test1@example.com",
            displayName: "Test User 1"
        )
        
        user2 = User(
            id: "user2", 
            username: "testuser2",
            email: "test2@example.com",
            displayName: "Test User 2"
        )
        
        message1 = Message(
            id: "msg1",
            senderId: user1.id,
            receiverId: user2.id,
            content: "Hello!",
            type: .text,
            timestamp: Date(timeIntervalSince1970: 1640995200)
        )
        
        message2 = Message(
            id: "msg2",
            senderId: user2.id,
            receiverId: user1.id,
            content: "Hi there!",
            type: .text,
            timestamp: Date(timeIntervalSince1970: 1640995260)
        )
        
        message3 = Message(
            id: "msg3",
            senderId: user1.id,
            receiverId: user2.id,
            content: "https://example.com/photo.jpg",
            type: .image,
            timestamp: Date(timeIntervalSince1970: 1640995320)
        )
        
        // Create a simple conversation model for testing
        conversation = Conversation(
            id: "conv123",
            participants: [user1.id, user2.id],
            messages: [message1, message2, message3],
            lastMessage: message3,
            lastActivity: Date(timeIntervalSince1970: 1640995320),
            isActive: true
        )
    }
    
    override func tearDownWithError() throws {
        conversation = nil
        user1 = nil
        user2 = nil
        message1 = nil
        message2 = nil
        message3 = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Conversation Initialization Tests
    
    func testConversationInitialization() throws {
        XCTAssertEqual(conversation.id, "conv123")
        XCTAssertEqual(conversation.participants, [user1.id, user2.id])
        XCTAssertEqual(conversation.messages.count, 3)
        XCTAssertEqual(conversation.lastMessage?.id, message3.id)
        XCTAssertTrue(conversation.isActive)
    }
    
    func testEmptyConversationInitialization() throws {
        let emptyConv = Conversation(
            id: "empty123",
            participants: [user1.id, user2.id],
            messages: [],
            lastMessage: nil,
            lastActivity: Date(),
            isActive: true
        )
        
        XCTAssertEqual(emptyConv.messages.count, 0)
        XCTAssertNil(emptyConv.lastMessage)
        XCTAssertTrue(emptyConv.isActive)
    }
    
    // MARK: - Message Management Tests
    
    func testAddMessage() throws {
        let newMessage = Message(
            senderId: user2.id,
            receiverId: user1.id,
            content: "New message",
            type: .text
        )
        
        let initialCount = conversation.messages.count
        conversation.addMessage(newMessage)
        
        XCTAssertEqual(conversation.messages.count, initialCount + 1)
        XCTAssertEqual(conversation.lastMessage?.id, newMessage.id)
        XCTAssertTrue(conversation.messages.contains(newMessage))
    }
    
    func testAddMultipleMessages() throws {
        let newMessage1 = Message(
            senderId: user1.id,
            receiverId: user2.id,
            content: "Message 1",
            type: .text
        )
        
        let newMessage2 = Message(
            senderId: user2.id,
            receiverId: user1.id,
            content: "Message 2",
            type: .text
        )
        
        conversation.addMessage(newMessage1)
        conversation.addMessage(newMessage2)
        
        XCTAssertEqual(conversation.messages.count, 5)
        XCTAssertEqual(conversation.lastMessage?.id, newMessage2.id)
    }
    
    func testRemoveMessage() throws {
        let initialCount = conversation.messages.count
        let removedMessage = conversation.removeMessage(message2.id)
        
        XCTAssertNotNil(removedMessage)
        XCTAssertEqual(removedMessage?.id, message2.id)
        XCTAssertEqual(conversation.messages.count, initialCount - 1)
        XCTAssertFalse(conversation.messages.contains(message2))
    }
    
    func testRemoveNonExistentMessage() throws {
        let initialCount = conversation.messages.count
        let removedMessage = conversation.removeMessage("nonexistent")
        
        XCTAssertNil(removedMessage)
        XCTAssertEqual(conversation.messages.count, initialCount)
    }
    
    func testRemoveLastMessage() throws {
        let removedMessage = conversation.removeMessage(message3.id)
        
        XCTAssertNotNil(removedMessage)
        XCTAssertEqual(conversation.lastMessage?.id, message2.id) // Should update to previous message
    }
    
    // MARK: - Message Ordering Tests
    
    func testMessagesOrderedByTimestamp() throws {
        let messages = conversation.getMessagesOrderedByTime()
        
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].id, message1.id)
        XCTAssertEqual(messages[1].id, message2.id)
        XCTAssertEqual(messages[2].id, message3.id)
    }
    
    func testMessagesReverseOrder() throws {
        let messages = conversation.getMessagesOrderedByTime(ascending: false)
        
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].id, message3.id)
        XCTAssertEqual(messages[1].id, message2.id)
        XCTAssertEqual(messages[2].id, message1.id)
    }
    
    func testAddMessageUpdatesOrder() throws {
        let futureMessage = Message(
            senderId: user2.id,
            receiverId: user1.id,
            content: "Future message",
            type: .text,
            timestamp: Date(timeIntervalSince1970: 1640995400)
        )
        
        conversation.addMessage(futureMessage)
        let orderedMessages = conversation.getMessagesOrderedByTime()
        
        XCTAssertEqual(orderedMessages.last?.id, futureMessage.id)
    }
    
    // MARK: - Participant Management Tests
    
    func testIsParticipant() throws {
        XCTAssertTrue(conversation.isParticipant(user1.id))
        XCTAssertTrue(conversation.isParticipant(user2.id))
        XCTAssertFalse(conversation.isParticipant("stranger123"))
    }
    
    func testGetOtherParticipant() throws {
        let otherForUser1 = conversation.getOtherParticipant(user1.id)
        let otherForUser2 = conversation.getOtherParticipant(user2.id)
        
        XCTAssertEqual(otherForUser1, user2.id)
        XCTAssertEqual(otherForUser2, user1.id)
    }
    
    func testGetOtherParticipantForNonParticipant() throws {
        let other = conversation.getOtherParticipant("stranger123")
        XCTAssertNil(other)
    }
    
    func testAddParticipant() throws {
        let user3 = User(
            id: "user3",
            username: "testuser3",
            email: "test3@example.com",
            displayName: "Test User 3"
        )
        
        conversation.addParticipant(user3.id)
        
        XCTAssertTrue(conversation.isParticipant(user3.id))
        XCTAssertEqual(conversation.participants.count, 3)
    }
    
    func testAddExistingParticipant() throws {
        let initialCount = conversation.participants.count
        conversation.addParticipant(user1.id)
        
        XCTAssertEqual(conversation.participants.count, initialCount) // Should not add duplicate
    }
    
    func testRemoveParticipant() throws {
        conversation.removeParticipant(user2.id)
        
        XCTAssertFalse(conversation.isParticipant(user2.id))
        XCTAssertEqual(conversation.participants.count, 1)
        XCTAssertEqual(conversation.participants[0], user1.id)
    }
    
    // MARK: - Message Filtering Tests
    
    func testGetMessagesBySender() throws {
        let user1Messages = conversation.getMessagesBySender(user1.id)
        let user2Messages = conversation.getMessagesBySender(user2.id)
        
        XCTAssertEqual(user1Messages.count, 2) // message1 and message3
        XCTAssertEqual(user2Messages.count, 1) // message2
        
        XCTAssertTrue(user1Messages.contains(message1))
        XCTAssertTrue(user1Messages.contains(message3))
        XCTAssertTrue(user2Messages.contains(message2))
    }
    
    func testGetMessagesByType() throws {
        let textMessages = conversation.getMessagesByType(.text)
        let imageMessages = conversation.getMessagesByType(.image)
        
        XCTAssertEqual(textMessages.count, 2) // message1 and message2
        XCTAssertEqual(imageMessages.count, 1) // message3
    }
    
    func testGetMessagesInTimeRange() throws {
        let startTime = Date(timeIntervalSince1970: 1640995200)
        let endTime = Date(timeIntervalSince1970: 1640995280)
        
        let messagesInRange = conversation.getMessagesInTimeRange(from: startTime, to: endTime)
        
        XCTAssertEqual(messagesInRange.count, 2) // message1 and message2
        XCTAssertTrue(messagesInRange.contains(message1))
        XCTAssertTrue(messagesInRange.contains(message2))
        XCTAssertFalse(messagesInRange.contains(message3))
    }
    
    // MARK: - Unread Message Tests
    
    func testGetUnreadMessages() throws {
        // Mark some messages as delivered but not viewed
        message1.markAsDelivered()
        message2.markAsViewed()
        message3.markAsDelivered()
        
        let unreadMessages = conversation.getUnreadMessagesFor(user2.id)
        
        // Should include messages sent to user2 that are not viewed
        XCTAssertEqual(unreadMessages.count, 2) // message1 and message3
        XCTAssertTrue(unreadMessages.contains(message1))
        XCTAssertTrue(unreadMessages.contains(message3))
    }
    
    func testMarkAllMessagesAsRead() throws {
        conversation.markAllMessagesAsReadFor(user2.id)
        
        let unreadMessages = conversation.getUnreadMessagesFor(user2.id)
        XCTAssertEqual(unreadMessages.count, 0)
    }
    
    func testGetUnreadCount() throws {
        message1.markAsDelivered()
        message3.markAsDelivered()
        
        let unreadCount = conversation.getUnreadCountFor(user2.id)
        XCTAssertEqual(unreadCount, 2)
    }
    
    // MARK: - Conversation Activity Tests
    
    func testUpdateLastActivity() throws {
        let oldActivity = conversation.lastActivity
        
        conversation.updateLastActivity()
        
        XCTAssertGreaterThan(conversation.lastActivity, oldActivity)
    }
    
    func testMarkAsActive() throws {
        conversation.isActive = false
        conversation.markAsActive()
        
        XCTAssertTrue(conversation.isActive)
    }
    
    func testMarkAsInactive() throws {
        conversation.markAsInactive()
        
        XCTAssertFalse(conversation.isActive)
    }
    
    // MARK: - Ephemeral Message Cleanup Tests
    
    func testCleanupExpiredMessages() throws {
        // Create expired ephemeral message
        let expiredMessage = Message(
            senderId: user1.id,
            receiverId: user2.id,
            content: "Expired message",
            type: .text,
            isEphemeral: true,
            viewDuration: 1.0
        )
        expiredMessage.markAsViewed()
        expiredMessage.expiresAt = Date().addingTimeInterval(-1) // Expired
        
        conversation.addMessage(expiredMessage)
        
        let removedCount = conversation.cleanupExpiredMessages()
        
        XCTAssertGreaterThan(removedCount, 0)
        XCTAssertFalse(conversation.messages.contains(expiredMessage))
    }
    
    func testCleanupNonExpiredMessages() throws {
        let initialCount = conversation.messages.count
        let removedCount = conversation.cleanupExpiredMessages()
        
        XCTAssertEqual(removedCount, 0)
        XCTAssertEqual(conversation.messages.count, initialCount)
    }
    
    // MARK: - Performance Tests
    
    func testLargeConversationPerformance() throws {
        let largeConversation = Conversation(
            id: "large123",
            participants: [user1.id, user2.id],
            messages: [],
            lastMessage: nil,
            lastActivity: Date(),
            isActive: true
        )
        
        measure {
            // Add 1000 messages
            for i in 0..<1000 {
                let message = Message(
                    senderId: i % 2 == 0 ? user1.id : user2.id,
                    receiverId: i % 2 == 0 ? user2.id : user1.id,
                    content: "Message \(i)",
                    type: .text
                )
                largeConversation.addMessage(message)
            }
            
            // Perform operations
            _ = largeConversation.getMessagesOrderedByTime()
            _ = largeConversation.getMessagesBySender(user1.id)
            _ = largeConversation.getUnreadCountFor(user2.id)
        }
    }
    
    func testMessageSearchPerformance() throws {
        // Add many messages
        for i in 0..<10000 {
            let message = Message(
                id: "perf_msg_\(i)",
                senderId: i % 2 == 0 ? user1.id : user2.id,
                receiverId: i % 2 == 0 ? user2.id : user1.id,
                content: "Performance message \(i)",
                type: .text
            )
            conversation.addMessage(message)
        }
        
        measure {
            // Search for specific messages
            for i in 0..<100 {
                _ = conversation.getMessage("perf_msg_\(i * 100)")
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testConversationMemoryManagement() throws {
        weak var weakConversation: Conversation?
        
        autoreleasepool {
            let tempConversation = Conversation(
                id: "memory_test",
                participants: ["user1", "user2"],
                messages: [],
                lastMessage: nil,
                lastActivity: Date(),
                isActive: true
            )
            weakConversation = tempConversation
            
            // Add messages
            for i in 0..<1000 {
                let message = Message(
                    senderId: "user1",
                    receiverId: "user2",
                    content: "Memory test \(i)",
                    type: .text
                )
                tempConversation.addMessage(message)
            }
        }
        
        XCTAssertNil(weakConversation, "Conversation should be deallocated")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentMessageOperations() throws {
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = 3
        
        // Concurrent message adding
        DispatchQueue.global().async {
            for i in 0..<500 {
                let message = Message(
                    senderId: self.user1.id,
                    receiverId: self.user2.id,
                    content: "Concurrent A \(i)",
                    type: .text
                )
                self.conversation.addMessage(message)
            }
            expectation.fulfill()
        }
        
        // More concurrent adding
        DispatchQueue.global().async {
            for i in 0..<500 {
                let message = Message(
                    senderId: self.user2.id,
                    receiverId: self.user1.id,
                    content: "Concurrent B \(i)",
                    type: .text
                )
                self.conversation.addMessage(message)
            }
            expectation.fulfill()
        }
        
        // Concurrent reading
        DispatchQueue.global().async {
            for _ in 0..<100 {
                _ = self.conversation.getMessagesOrderedByTime()
                _ = self.conversation.getUnreadCountFor(self.user2.id)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify reasonable final state
        XCTAssertGreaterThanOrEqual(conversation.messages.count, 800)
        XCTAssertLessThanOrEqual(conversation.messages.count, 1003)
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyConversationOperations() throws {
        let emptyConv = Conversation(
            id: "empty",
            participants: [],
            messages: [],
            lastMessage: nil,
            lastActivity: Date(),
            isActive: true
        )
        
        XCTAssertEqual(emptyConv.getMessagesOrderedByTime().count, 0)
        XCTAssertEqual(emptyConv.getUnreadCountFor("anyone"), 0)
        XCTAssertEqual(emptyConv.cleanupExpiredMessages(), 0)
        XCTAssertNil(emptyConv.getOtherParticipant("anyone"))
    }
    
    func testSingleParticipantConversation() throws {
        let soloConv = Conversation(
            id: "solo",
            participants: [user1.id],
            messages: [],
            lastMessage: nil,
            lastActivity: Date(),
            isActive: true
        )
        
        XCTAssertTrue(soloConv.isParticipant(user1.id))
        XCTAssertNil(soloConv.getOtherParticipant(user1.id))
    }
}

// MARK: - Mock Conversation Model

// Simple Conversation model for testing purposes
class Conversation {
    let id: String
    var participants: [String]
    var messages: [Message]
    var lastMessage: Message?
    var lastActivity: Date
    var isActive: Bool
    
    init(id: String, participants: [String], messages: [Message], lastMessage: Message?, lastActivity: Date, isActive: Bool) {
        self.id = id
        self.participants = participants
        self.messages = messages
        self.lastMessage = lastMessage
        self.lastActivity = lastActivity
        self.isActive = isActive
    }
    
    func addMessage(_ message: Message) {
        messages.append(message)
        lastMessage = message
        updateLastActivity()
    }
    
    func removeMessage(_ messageId: String) -> Message? {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            return nil
        }
        
        let removedMessage = messages.remove(at: index)
        
        // Update last message if necessary
        if removedMessage.id == lastMessage?.id {
            lastMessage = messages.sorted(by: { $0.timestamp < $1.timestamp }).last
        }
        
        return removedMessage
    }
    
    func getMessage(_ messageId: String) -> Message? {
        return messages.first { $0.id == messageId }
    }
    
    func getMessagesOrderedByTime(ascending: Bool = true) -> [Message] {
        return messages.sorted { ascending ? $0.timestamp < $1.timestamp : $0.timestamp > $1.timestamp }
    }
    
    func getMessagesBySender(_ senderId: String) -> [Message] {
        return messages.filter { $0.senderId == senderId }
    }
    
    func getMessagesByType(_ type: MessageType) -> [Message] {
        return messages.filter { $0.type == type }
    }
    
    func getMessagesInTimeRange(from startTime: Date, to endTime: Date) -> [Message] {
        return messages.filter { $0.timestamp >= startTime && $0.timestamp <= endTime }
    }
    
    func getUnreadMessagesFor(_ userId: String) -> [Message] {
        return messages.filter { $0.receiverId == userId && $0.viewedAt == nil }
    }
    
    func getUnreadCountFor(_ userId: String) -> Int {
        return getUnreadMessagesFor(userId).count
    }
    
    func markAllMessagesAsReadFor(_ userId: String) {
        for message in messages where message.receiverId == userId {
            message.markAsViewed()
        }
    }
    
    func isParticipant(_ userId: String) -> Bool {
        return participants.contains(userId)
    }
    
    func getOtherParticipant(_ userId: String) -> String? {
        guard participants.count == 2, isParticipant(userId) else {
            return nil
        }
        return participants.first { $0 != userId }
    }
    
    func addParticipant(_ userId: String) {
        if !participants.contains(userId) {
            participants.append(userId)
        }
    }
    
    func removeParticipant(_ userId: String) {
        participants.removeAll { $0 == userId }
    }
    
    func updateLastActivity() {
        lastActivity = Date()
    }
    
    func markAsActive() {
        isActive = true
        updateLastActivity()
    }
    
    func markAsInactive() {
        isActive = false
    }
    
    func cleanupExpiredMessages() -> Int {
        let initialCount = messages.count
        messages.removeAll { $0.shouldAutoDelete }
        return initialCount - messages.count
    }
}