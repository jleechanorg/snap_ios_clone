//
//  MessageTests.swift
//  SnapCloneTests
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Comprehensive tests for Message model, ephemeral messaging, auto-delete, and status tracking
//

import XCTest
import FirebaseFirestore
@testable import SnapClone

final class MessageTests: XCTestCase {
    
    // MARK: - Properties
    
    var sampleMessage: Message!
    var ephemeralMessage: Message!
    var mediaMessage: Message!
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        sampleMessage = Message(
            id: "msg123",
            senderId: "user123",
            receiverId: "user456",
            content: "Hello, World!",
            type: .text,
            timestamp: Date(timeIntervalSince1970: 1640995200),
            isEphemeral: false,
            viewDuration: 10.0,
            status: .sent
        )
        
        ephemeralMessage = Message(
            id: "ephemeral123",
            senderId: "user123",
            receiverId: "user456",
            content: "This will disappear!",
            type: .text,
            isEphemeral: true,
            viewDuration: 5.0
        )
        
        mediaMessage = Message(
            id: "media123",
            senderId: "user123",
            receiverId: "user456",
            content: "https://example.com/photo.jpg",
            type: .image,
            isEphemeral: true,
            viewDuration: 10.0
        )
    }
    
    override func tearDownWithError() throws {
        sampleMessage = nil
        ephemeralMessage = nil
        mediaMessage = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testMessageInitialization() throws {
        XCTAssertEqual(sampleMessage.id, "msg123")
        XCTAssertEqual(sampleMessage.senderId, "user123")
        XCTAssertEqual(sampleMessage.receiverId, "user456")
        XCTAssertEqual(sampleMessage.content, "Hello, World!")
        XCTAssertEqual(sampleMessage.type, .text)
        XCTAssertFalse(sampleMessage.isEphemeral)
        XCTAssertEqual(sampleMessage.viewDuration, 10.0)
        XCTAssertEqual(sampleMessage.status, .sent)
        XCTAssertNil(sampleMessage.viewedAt)
        XCTAssertNil(sampleMessage.expiresAt)
    }
    
    func testMessageDefaultInitialization() throws {
        let message = Message(
            senderId: "sender123",
            receiverId: "receiver123",
            content: "Default message",
            type: .text
        )
        
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertEqual(message.senderId, "sender123")
        XCTAssertEqual(message.receiverId, "receiver123")
        XCTAssertEqual(message.content, "Default message")
        XCTAssertEqual(message.type, .text)
        XCTAssertTrue(message.isEphemeral)
        XCTAssertEqual(message.viewDuration, 10.0)
        XCTAssertEqual(message.status, .sent)
        XCTAssertNil(message.viewedAt)
        XCTAssertNil(message.expiresAt)
    }
    
    func testTextMessageConvenienceInitializer() throws {
        let textMessage = Message(
            textMessage: "sender123",
            receiverId: "receiver123",
            text: "Hello from convenience init",
            isEphemeral: false,
            viewDuration: 15.0
        )
        
        XCTAssertEqual(textMessage.senderId, "sender123")
        XCTAssertEqual(textMessage.receiverId, "receiver123")
        XCTAssertEqual(textMessage.content, "Hello from convenience init")
        XCTAssertEqual(textMessage.type, .text)
        XCTAssertFalse(textMessage.isEphemeral)
        XCTAssertEqual(textMessage.viewDuration, 15.0)
    }
    
    func testMediaMessageConvenienceInitializer() throws {
        let mediaMessage = Message(
            mediaMessage: "sender123",
            receiverId: "receiver123",
            mediaURL: "https://example.com/video.mp4",
            type: .video,
            isEphemeral: true,
            viewDuration: 20.0
        )
        
        XCTAssertEqual(mediaMessage.senderId, "sender123")
        XCTAssertEqual(mediaMessage.receiverId, "receiver123")
        XCTAssertEqual(mediaMessage.content, "https://example.com/video.mp4")
        XCTAssertEqual(mediaMessage.type, .video)
        XCTAssertTrue(mediaMessage.isEphemeral)
        XCTAssertEqual(mediaMessage.viewDuration, 20.0)
    }
    
    // MARK: - Message Type Tests
    
    func testMessageTypeDisplayNames() throws {
        XCTAssertEqual(MessageType.text.displayName, "Text")
        XCTAssertEqual(MessageType.image.displayName, "Image")
        XCTAssertEqual(MessageType.video.displayName, "Video")
        XCTAssertEqual(MessageType.audio.displayName, "Audio")
    }
    
    func testMessageTypeRawValues() throws {
        XCTAssertEqual(MessageType.text.rawValue, "text")
        XCTAssertEqual(MessageType.image.rawValue, "image")
        XCTAssertEqual(MessageType.video.rawValue, "video")
        XCTAssertEqual(MessageType.audio.rawValue, "audio")
    }
    
    func testMessageTypeCaseIterable() throws {
        let allTypes = MessageType.allCases
        XCTAssertEqual(allTypes.count, 4)
        XCTAssertTrue(allTypes.contains(.text))
        XCTAssertTrue(allTypes.contains(.image))
        XCTAssertTrue(allTypes.contains(.video))
        XCTAssertTrue(allTypes.contains(.audio))
    }
    
    // MARK: - Message Status Tests
    
    func testMessageStatusDisplayNames() throws {
        XCTAssertEqual(MessageStatus.sent.displayName, "Sent")
        XCTAssertEqual(MessageStatus.delivered.displayName, "Delivered")
        XCTAssertEqual(MessageStatus.viewed.displayName, "Viewed")
        XCTAssertEqual(MessageStatus.expired.displayName, "Expired")
    }
    
    func testMessageStatusRawValues() throws {
        XCTAssertEqual(MessageStatus.sent.rawValue, "sent")
        XCTAssertEqual(MessageStatus.delivered.rawValue, "delivered")
        XCTAssertEqual(MessageStatus.viewed.rawValue, "viewed")
        XCTAssertEqual(MessageStatus.expired.rawValue, "expired")
    }
    
    func testMessageStatusCaseIterable() throws {
        let allStatuses = MessageStatus.allCases
        XCTAssertEqual(allStatuses.count, 4)
        XCTAssertTrue(allStatuses.contains(.sent))
        XCTAssertTrue(allStatuses.contains(.delivered))
        XCTAssertTrue(allStatuses.contains(.viewed))
        XCTAssertTrue(allStatuses.contains(.expired))
    }
    
    // MARK: - Status Transition Tests
    
    func testMarkAsDelivered() throws {
        XCTAssertEqual(sampleMessage.status, .sent)
        
        sampleMessage.markAsDelivered()
        XCTAssertEqual(sampleMessage.status, .delivered)
        
        // Should not change if already delivered
        sampleMessage.markAsDelivered()
        XCTAssertEqual(sampleMessage.status, .delivered)
    }
    
    func testMarkAsDeliveredFromNonSentStatus() throws {
        sampleMessage.status = .viewed
        sampleMessage.markAsDelivered()
        XCTAssertEqual(sampleMessage.status, .viewed) // Should not change
    }
    
    func testMarkAsExpired() throws {
        sampleMessage.markAsExpired()
        XCTAssertEqual(sampleMessage.status, .expired)
    }
    
    // MARK: - Ephemeral Message Logic Tests
    
    func testCanBeViewed() throws {
        // New ephemeral message should be viewable
        XCTAssertTrue(ephemeralMessage.canBeViewed)
        
        // After viewing, should not be viewable if expired
        ephemeralMessage.markAsViewed()
        ephemeralMessage.expiresAt = Date().addingTimeInterval(-1) // Expired
        XCTAssertFalse(ephemeralMessage.canBeViewed)
    }
    
    func testMarkAsViewed() throws {
        let beforeViewing = Date()
        ephemeralMessage.markAsViewed()
        let afterViewing = Date()
        
        XCTAssertNotNil(ephemeralMessage.viewedAt)
        XCTAssertEqual(ephemeralMessage.status, .viewed)
        XCTAssertNotNil(ephemeralMessage.expiresAt)
        
        // Check that viewedAt is between before and after timestamps
        if let viewedAt = ephemeralMessage.viewedAt {
            XCTAssertGreaterThanOrEqual(viewedAt, beforeViewing)
            XCTAssertLessThanOrEqual(viewedAt, afterViewing)
        }
        
        // Check that expiration is set correctly for ephemeral messages
        if let expiresAt = ephemeralMessage.expiresAt, let viewedAt = ephemeralMessage.viewedAt {
            let expectedExpiry = viewedAt.addingTimeInterval(ephemeralMessage.viewDuration)
            XCTAssertEqual(expiresAt.timeIntervalSince1970, expectedExpiry.timeIntervalSince1970, accuracy: 1.0)
        }
    }
    
    func testMarkAsViewedNonEphemeral() throws {
        sampleMessage.markAsViewed()
        
        XCTAssertNotNil(sampleMessage.viewedAt)
        XCTAssertEqual(sampleMessage.status, .viewed)
        XCTAssertNil(sampleMessage.expiresAt) // Should not set expiration for non-ephemeral
    }
    
    func testMarkAsViewedAlreadyExpired() throws {
        ephemeralMessage.expiresAt = Date().addingTimeInterval(-1) // Already expired
        ephemeralMessage.markAsViewed()
        
        XCTAssertNil(ephemeralMessage.viewedAt) // Should not mark as viewed
        XCTAssertEqual(ephemeralMessage.status, .sent) // Status should not change
    }
    
    func testHasExpired() throws {
        // Not expired initially
        XCTAssertFalse(ephemeralMessage.hasExpired)
        
        // Set expiration in the past
        ephemeralMessage.expiresAt = Date().addingTimeInterval(-1)
        XCTAssertTrue(ephemeralMessage.hasExpired)
        
        // Set expiration in the future
        ephemeralMessage.expiresAt = Date().addingTimeInterval(10)
        XCTAssertFalse(ephemeralMessage.hasExpired)
        
        // No expiration set
        ephemeralMessage.expiresAt = nil
        XCTAssertFalse(ephemeralMessage.hasExpired)
    }
    
    func testShouldAutoDelete() throws {
        // Initially should not auto-delete
        XCTAssertFalse(ephemeralMessage.shouldAutoDelete)
        
        // Mark as viewed but not expired yet
        ephemeralMessage.markAsViewed()
        XCTAssertFalse(ephemeralMessage.shouldAutoDelete)
        
        // Set expiration in the past
        ephemeralMessage.expiresAt = Date().addingTimeInterval(-1)
        XCTAssertTrue(ephemeralMessage.shouldAutoDelete)
    }
    
    func testShouldAutoDeleteBasedOnViewDuration() throws {
        // Mark as viewed with very short duration
        ephemeralMessage.viewDuration = 0.1
        ephemeralMessage.markAsViewed(at: Date().addingTimeInterval(-1)) // Viewed 1 second ago
        
        XCTAssertTrue(ephemeralMessage.shouldAutoDelete)
    }
    
    func testRemainingViewTime() throws {
        // No view time for unviewed message
        XCTAssertNil(ephemeralMessage.remainingViewTime)
        
        // Mark as viewed recently
        let viewTime = Date().addingTimeInterval(-2) // Viewed 2 seconds ago
        ephemeralMessage.markAsViewed(at: viewTime)
        
        if let remaining = ephemeralMessage.remainingViewTime {
            XCTAssertGreaterThanOrEqual(remaining, 2.0)
            XCTAssertLessThanOrEqual(remaining, 4.0) // Should be around 3 seconds (5-2)
        }
        
        // Fully expired
        let oldViewTime = Date().addingTimeInterval(-10) // Viewed 10 seconds ago
        ephemeralMessage.markAsViewed(at: oldViewTime)
        
        if let remaining = ephemeralMessage.remainingViewTime {
            XCTAssertEqual(remaining, 0.0)
        }
    }
    
    func testRemainingViewTimeNonEphemeral() throws {
        sampleMessage.markAsViewed()
        XCTAssertNil(sampleMessage.remainingViewTime)
    }
    
    // MARK: - Utility Methods Tests
    
    func testFormattedTimestamp() throws {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        
        // Today's message
        let todayMessage = Message(
            senderId: "sender123",
            receiverId: "receiver123",
            content: "Today",
            type: .text,
            timestamp: now
        )
        
        let todayFormatted = todayMessage.formattedTimestamp
        XCTAssertTrue(todayFormatted.contains(":")) // Should contain time format HH:mm
        
        // Yesterday's message
        let yesterdayMessage = Message(
            senderId: "sender123",
            receiverId: "receiver123",
            content: "Yesterday",
            type: .text,
            timestamp: yesterday
        )
        
        XCTAssertEqual(yesterdayMessage.formattedTimestamp, "Yesterday")
        
        // Last week's message
        let lastWeekMessage = Message(
            senderId: "sender123",
            receiverId: "receiver123",
            content: "Last week",
            type: .text,
            timestamp: lastWeek
        )
        
        let lastWeekFormatted = lastWeekMessage.formattedTimestamp
        XCTAssertFalse(lastWeekFormatted.contains(":"))
        XCTAssertFalse(lastWeekFormatted == "Yesterday")
    }
    
    func testIsFromCurrentUser() throws {
        XCTAssertTrue(sampleMessage.isFromCurrentUser("user123"))
        XCTAssertFalse(sampleMessage.isFromCurrentUser("user456"))
        XCTAssertFalse(sampleMessage.isFromCurrentUser("different123"))
    }
    
    // MARK: - Equality and Hashing Tests
    
    func testEquality() throws {
        let message1 = Message(
            id: "same123",
            senderId: "sender1",
            receiverId: "receiver1",
            content: "Message 1",
            type: .text
        )
        
        let message2 = Message(
            id: "same123",
            senderId: "sender2",
            receiverId: "receiver2",
            content: "Message 2",
            type: .image
        )
        
        let message3 = Message(
            id: "different123",
            senderId: "sender3",
            receiverId: "receiver3",
            content: "Message 3",
            type: .text
        )
        
        XCTAssertEqual(message1, message2) // Same ID
        XCTAssertNotEqual(message1, message3) // Different ID
    }
    
    func testHashing() throws {
        let message1 = Message(
            id: "hash123",
            senderId: "sender1",
            receiverId: "receiver1",
            content: "Message 1",
            type: .text
        )
        
        let message2 = Message(
            id: "hash123",
            senderId: "sender2",
            receiverId: "receiver2",
            content: "Message 2",
            type: .image
        )
        
        XCTAssertEqual(message1.hashValue, message2.hashValue)
    }
    
    // MARK: - Firebase Integration Tests
    
    func testToDictionary() throws {
        let dictionary = sampleMessage.toDictionary()
        
        XCTAssertEqual(dictionary["id"] as? String, "msg123")
        XCTAssertEqual(dictionary["senderId"] as? String, "user123")
        XCTAssertEqual(dictionary["receiverId"] as? String, "user456")
        XCTAssertEqual(dictionary["content"] as? String, "Hello, World!")
        XCTAssertEqual(dictionary["type"] as? String, "text")
        XCTAssertEqual(dictionary["isEphemeral"] as? Bool, false)
        XCTAssertEqual(dictionary["viewDuration"] as? TimeInterval, 10.0)
        XCTAssertEqual(dictionary["status"] as? String, "sent")
        
        // Check Timestamp conversion
        XCTAssertTrue(dictionary["timestamp"] is Timestamp)
        
        // Optional fields should not be present if nil
        XCTAssertNil(dictionary["expiresAt"])
        XCTAssertNil(dictionary["viewedAt"])
    }
    
    func testToDictionaryWithOptionalFields() throws {
        ephemeralMessage.markAsViewed()
        let dictionary = ephemeralMessage.toDictionary()
        
        XCTAssertTrue(dictionary["expiresAt"] is Timestamp)
        XCTAssertTrue(dictionary["viewedAt"] is Timestamp)
    }
    
    func testToDictionaryWithMetadata() throws {
        sampleMessage.metadata = ["key1": "value1", "key2": 42]
        let dictionary = sampleMessage.toDictionary()
        
        let metadata = dictionary["metadata"] as? [String: Any]
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?["key1"] as? String, "value1")
        XCTAssertEqual(metadata?["key2"] as? Int, 42)
    }
    
    // MARK: - Codable Tests
    
    func testCodableEncoding() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(sampleMessage)
        XCTAssertFalse(data.isEmpty)
    }
    
    func testCodableDecoding() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(sampleMessage)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(Message.self, from: data)
        
        XCTAssertEqual(decodedMessage.id, sampleMessage.id)
        XCTAssertEqual(decodedMessage.senderId, sampleMessage.senderId)
        XCTAssertEqual(decodedMessage.receiverId, sampleMessage.receiverId)
        XCTAssertEqual(decodedMessage.content, sampleMessage.content)
        XCTAssertEqual(decodedMessage.type, sampleMessage.type)
        XCTAssertEqual(decodedMessage.isEphemeral, sampleMessage.isEphemeral)
        XCTAssertEqual(decodedMessage.viewDuration, sampleMessage.viewDuration)
        XCTAssertEqual(decodedMessage.status, sampleMessage.status)
    }
    
    func testCodableDecodingWithMissingOptionalFields() throws {
        let json = """
        {
            "id": "minimal123",
            "senderId": "sender123",
            "receiverId": "receiver123",
            "content": "Minimal message",
            "type": "text",
            "timestamp": 1640995200
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let message = try decoder.decode(Message.self, from: data)
        
        XCTAssertEqual(message.id, "minimal123")
        XCTAssertNil(message.expiresAt)
        XCTAssertNil(message.viewedAt)
        XCTAssertTrue(message.isEphemeral) // Default value
        XCTAssertEqual(message.viewDuration, 10.0) // Default value
        XCTAssertEqual(message.status, .sent) // Default value
        XCTAssertTrue(message.metadata.isEmpty) // Default value
    }
    
    // MARK: - Performance Tests
    
    func testEphemeralLogicPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let message = Message(
                    senderId: "perf_sender",
                    receiverId: "perf_receiver",
                    content: "Performance test",
                    type: .text,
                    isEphemeral: true,
                    viewDuration: 5.0
                )
                
                message.markAsViewed()
                _ = message.hasExpired
                _ = message.canBeViewed
                _ = message.shouldAutoDelete
                _ = message.remainingViewTime
            }
        }
    }
    
    func testDictionaryConversionPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = sampleMessage.toDictionary()
            }
        }
    }
    
    func testCodingPerformance() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        measure {
            for _ in 0..<1000 {
                do {
                    let data = try encoder.encode(sampleMessage)
                    _ = try decoder.decode(Message.self, from: data)
                } catch {
                    XCTFail("Coding failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroViewDuration() throws {
        let message = Message(
            senderId: "sender123",
            receiverId: "receiver123",
            content: "Zero duration",
            type: .text,
            isEphemeral: true,
            viewDuration: 0.0
        )
        
        message.markAsViewed()
        XCTAssertTrue(message.shouldAutoDelete)
        XCTAssertEqual(message.remainingViewTime, 0.0)
    }
    
    func testNegativeViewDuration() throws {
        let message = Message(
            senderId: "sender123",
            receiverId: "receiver123",
            content: "Negative duration",
            type: .text,
            isEphemeral: true,
            viewDuration: -5.0
        )
        
        message.markAsViewed()
        XCTAssertTrue(message.shouldAutoDelete)
        XCTAssertEqual(message.remainingViewTime, 0.0)
    }
    
    func testLongContent() throws {
        let longContent = String(repeating: "a", count: 100000)
        let message = Message(
            senderId: "sender123",
            receiverId: "receiver123",
            content: longContent,
            type: .text
        )
        
        XCTAssertEqual(message.content.count, 100000)
        
        // Test that it can still be encoded/decoded
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(Message.self, from: data)
        XCTAssertEqual(decodedMessage.content, longContent)
    }
    
    // MARK: - Memory Tests
    
    func testMemoryLeakPrevention() throws {
        weak var weakMessage: Message?
        
        autoreleasepool {
            let message = Message(
                senderId: "memory_sender",
                receiverId: "memory_receiver",
                content: "Memory test",
                type: .text
            )
            weakMessage = message
            
            // Perform operations
            message.markAsViewed()
            message.markAsDelivered()
            _ = message.toDictionary()
        }
        
        XCTAssertNil(weakMessage, "Message should be deallocated after autoreleasepool")
    }
    
    // MARK: - Auto-Delete Timing Tests
    
    func testAutoDeleteTiming() throws {
        let shortDurationMessage = Message(
            senderId: "sender123",
            receiverId: "receiver123",
            content: "Short duration",
            type: .text,
            isEphemeral: true,
            viewDuration: 0.1 // 100ms
        )
        
        shortDurationMessage.markAsViewed()
        
        // Should not auto-delete immediately
        XCTAssertFalse(shortDurationMessage.shouldAutoDelete)
        
        let expectation = XCTestExpectation(description: "Auto-delete after duration")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(shortDurationMessage.shouldAutoDelete)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentStatusUpdates() throws {
        let message = Message(
            senderId: "concurrent_sender",
            receiverId: "concurrent_receiver",
            content: "Concurrent test",
            type: .text
        )
        
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = 3
        
        // Concurrent delivery marking
        DispatchQueue.global().async {
            message.markAsDelivered()
            expectation.fulfill()
        }
        
        // Concurrent viewing
        DispatchQueue.global().async {
            message.markAsViewed()
            expectation.fulfill()
        }
        
        // Concurrent expiration
        DispatchQueue.global().async {
            message.markAsExpired()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify that the message has a valid final state
        XCTAssertTrue([.delivered, .viewed, .expired].contains(message.status))
    }
}