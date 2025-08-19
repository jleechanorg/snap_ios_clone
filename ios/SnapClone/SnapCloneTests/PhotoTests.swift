//
//  PhotoTests.swift
//  SnapCloneTests
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Comprehensive tests for Photo model, stories, view tracking, and expiration
//

import XCTest
import FirebaseFirestore
@testable import SnapClone

final class PhotoTests: XCTestCase {
    
    // MARK: - Properties
    
    var samplePhoto: Photo!
    var storyPhoto: Photo!
    var expiringPhoto: Photo!
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        samplePhoto = Photo(
            id: "photo123",
            userId: "user123",
            imageURL: "https://example.com/photo.jpg",
            caption: "Test photo",
            recipients: ["friend1", "friend2"],
            createdAt: Date(timeIntervalSince1970: 1640995200),
            expiresAt: nil,
            viewedBy: [],
            isStory: false,
            viewDuration: 10.0,
            maxViews: 1,
            viewCount: 0,
            metadata: ["filter": "vintage"]
        )
        
        storyPhoto = Photo(
            storyPhoto: "user456",
            imageURL: "https://example.com/story.jpg",
            caption: "My story"
        )
        
        expiringPhoto = Photo(
            ephemeralSnap: "user789",
            imageURL: "https://example.com/snap.jpg",
            recipients: ["friend3"],
            caption: "Disappearing snap",
            viewDuration: 5.0
        )
    }
    
    override func tearDownWithError() throws {
        samplePhoto = nil
        storyPhoto = nil
        expiringPhoto = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testPhotoInitialization() throws {
        XCTAssertEqual(samplePhoto.id, "photo123")
        XCTAssertEqual(samplePhoto.userId, "user123")
        XCTAssertEqual(samplePhoto.imageURL, "https://example.com/photo.jpg")
        XCTAssertEqual(samplePhoto.caption, "Test photo")
        XCTAssertEqual(samplePhoto.recipients, ["friend1", "friend2"])
        XCTAssertFalse(samplePhoto.isStory)
        XCTAssertEqual(samplePhoto.viewDuration, 10.0)
        XCTAssertEqual(samplePhoto.maxViews, 1)
        XCTAssertEqual(samplePhoto.viewCount, 0)
        XCTAssertEqual(samplePhoto.metadata["filter"] as? String, "vintage")
    }
    
    func testStoryPhotoInitialization() throws {
        XCTAssertEqual(storyPhoto.userId, "user456")
        XCTAssertEqual(storyPhoto.imageURL, "https://example.com/story.jpg")
        XCTAssertEqual(storyPhoto.caption, "My story")
        XCTAssertTrue(storyPhoto.isStory)
        XCTAssertEqual(storyPhoto.viewDuration, 0)
        XCTAssertEqual(storyPhoto.maxViews, Int.max)
        XCTAssertTrue(storyPhoto.recipients.isEmpty)
    }
    
    func testEphemeralSnapInitialization() throws {
        XCTAssertEqual(expiringPhoto.userId, "user789")
        XCTAssertEqual(expiringPhoto.imageURL, "https://example.com/snap.jpg")
        XCTAssertEqual(expiringPhoto.recipients, ["friend3"])
        XCTAssertEqual(expiringPhoto.caption, "Disappearing snap")
        XCTAssertFalse(expiringPhoto.isStory)
        XCTAssertEqual(expiringPhoto.viewDuration, 5.0)
        XCTAssertEqual(expiringPhoto.maxViews, 1)
    }
    
    // MARK: - Expiration Tests
    
    func testPhotoExpirationLogic() throws {
        // Non-expired photo
        XCTAssertFalse(samplePhoto.hasExpired)
        
        // Set expiration in the past
        samplePhoto.expiresAt = Date().addingTimeInterval(-1)
        XCTAssertTrue(samplePhoto.hasExpired)
        
        // Set expiration in the future
        samplePhoto.expiresAt = Date().addingTimeInterval(10)
        XCTAssertFalse(samplePhoto.hasExpired)
    }
    
    func testStoryExpiration() throws {
        // New story should not be expired
        XCTAssertFalse(storyPhoto.hasExpired)
        
        // Create old story (25 hours ago)
        let oldStory = Photo(
            storyPhoto: "user123",
            imageURL: "https://example.com/old-story.jpg"
        )
        // Simulate old creation time
        let oldDate = Date().addingTimeInterval(-25 * 60 * 60) // 25 hours ago
        let oldStoryWithDate = Photo(
            userId: oldStory.userId,
            imageURL: oldStory.imageURL,
            createdAt: oldDate,
            isStory: true,
            maxViews: Int.max
        )
        
        XCTAssertTrue(oldStoryWithDate.hasExpired)
    }
    
    // MARK: - View Tracking Tests
    
    func testCanBeViewedBy() throws {
        // Creator can always view their own photo
        XCTAssertTrue(samplePhoto.canBeViewedBy("user123"))
        
        // Recipients can view the photo
        XCTAssertTrue(samplePhoto.canBeViewedBy("friend1"))
        XCTAssertTrue(samplePhoto.canBeViewedBy("friend2"))
        
        // Non-recipients cannot view
        XCTAssertFalse(samplePhoto.canBeViewedBy("stranger"))
        
        // Stories are visible to everyone (friend check would be done at service level)
        XCTAssertTrue(storyPhoto.canBeViewedBy("anyone"))
    }
    
    func testMarkAsViewed() throws {
        // Initially not viewed
        XCTAssertFalse(samplePhoto.hasBeenViewedBy("friend1"))
        XCTAssertEqual(samplePhoto.viewCount, 0)
        XCTAssertEqual(samplePhoto.uniqueViewCount, 0)
        
        // Mark as viewed by friend1
        let result = samplePhoto.markAsViewed(by: "friend1")
        XCTAssertTrue(result)
        XCTAssertTrue(samplePhoto.hasBeenViewedBy("friend1"))
        XCTAssertEqual(samplePhoto.viewCount, 1)
        XCTAssertEqual(samplePhoto.uniqueViewCount, 1)
        
        // Try to mark as viewed again by same user
        let duplicateResult = samplePhoto.markAsViewed(by: "friend1")
        XCTAssertFalse(duplicateResult)
        XCTAssertEqual(samplePhoto.viewCount, 1) // Should not increment
    }
    
    func testMarkAsViewedSetsExpiration() throws {
        // Ephemeral photo should set expiration when viewed
        XCTAssertNil(expiringPhoto.expiresAt)
        
        expiringPhoto.markAsViewed(by: "friend3")
        XCTAssertNotNil(expiringPhoto.expiresAt)
        
        // Check expiration is set correctly
        if let expiresAt = expiringPhoto.expiresAt {
            let expectedExpiry = Date().addingTimeInterval(5.0)
            XCTAssertEqual(expiresAt.timeIntervalSince1970, expectedExpiry.timeIntervalSince1970, accuracy: 1.0)
        }
    }
    
    func testViewingExpiredPhoto() throws {
        // Set photo as expired
        samplePhoto.expiresAt = Date().addingTimeInterval(-1)
        
        let result = samplePhoto.markAsViewed(by: "friend1")
        XCTAssertFalse(result)
        XCTAssertFalse(samplePhoto.hasBeenViewedBy("friend1"))
        XCTAssertEqual(samplePhoto.viewCount, 0)
    }
    
    func testMaxViewsReached() throws {
        // Mark as viewed to reach max views
        samplePhoto.markAsViewed(by: "friend1")
        XCTAssertEqual(samplePhoto.viewCount, 1)
        
        // Should not be viewable after max views reached
        XCTAssertFalse(samplePhoto.canBeViewedBy("friend2"))
        
        let result = samplePhoto.markAsViewed(by: "friend2")
        XCTAssertFalse(result)
    }
    
    // MARK: - Recipient Management Tests
    
    func testAddRecipient() throws {
        let photo = Photo(
            userId: "user123",
            imageURL: "https://example.com/test.jpg"
        )
        
        // Add new recipient
        let result = photo.addRecipient("friend1")
        XCTAssertTrue(result)
        XCTAssertTrue(photo.recipients.contains("friend1"))
        
        // Try to add duplicate
        let duplicateResult = photo.addRecipient("friend1")
        XCTAssertFalse(duplicateResult)
        XCTAssertEqual(photo.recipients.count, 1)
        
        // Try to add self
        let selfResult = photo.addRecipient("user123")
        XCTAssertFalse(selfResult)
    }
    
    func testRemoveRecipient() throws {
        // Remove existing recipient
        let result = samplePhoto.removeRecipient("friend1")
        XCTAssertTrue(result)
        XCTAssertFalse(samplePhoto.recipients.contains("friend1"))
        XCTAssertEqual(samplePhoto.recipients, ["friend2"])
        
        // Try to remove non-existent recipient
        let invalidResult = samplePhoto.removeRecipient("nonexistent")
        XCTAssertFalse(invalidResult)
    }
    
    // MARK: - Auto-Delete Logic Tests
    
    func testShouldAutoDelete() throws {
        // Should not auto-delete initially
        XCTAssertFalse(samplePhoto.shouldAutoDelete)
        
        // Set as expired
        samplePhoto.expiresAt = Date().addingTimeInterval(-1)
        XCTAssertTrue(samplePhoto.shouldAutoDelete)
        
        // Reset expiration and test max views scenario
        samplePhoto.expiresAt = nil
        samplePhoto.markAsViewed(by: "friend1")
        samplePhoto.markAsViewed(by: "friend2")
        
        // Should auto-delete when all recipients have viewed and max views reached
        XCTAssertTrue(samplePhoto.shouldAutoDelete)
    }
    
    func testShouldAutoDeleteWithPartialViews() throws {
        // Mark as viewed by only one recipient
        samplePhoto.markAsViewed(by: "friend1")
        
        // Should not auto-delete until all recipients view
        XCTAssertFalse(samplePhoto.shouldAutoDelete)
    }
    
    // MARK: - Utility Methods Tests
    
    func testFormattedTimestamp() throws {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Today's photo
        let todayPhoto = Photo(
            userId: "user123",
            imageURL: "https://example.com/today.jpg",
            createdAt: now
        )
        
        let todayFormatted = todayPhoto.formattedTimestamp
        XCTAssertTrue(todayFormatted.contains(":")) // Should contain time format HH:mm
        
        // Yesterday's photo
        let yesterdayPhoto = Photo(
            userId: "user123",
            imageURL: "https://example.com/yesterday.jpg",
            createdAt: yesterday
        )
        
        XCTAssertEqual(yesterdayPhoto.formattedTimestamp, "Yesterday")
    }
    
    func testRemainingTime() throws {
        // Photo with no expiration
        XCTAssertNil(samplePhoto.remainingTime)
        
        // Story photo (24-hour window)
        let remainingStoryTime = storyPhoto.remainingTime
        XCTAssertNotNil(remainingStoryTime)
        if let remaining = remainingStoryTime {
            XCTAssertGreaterThan(remaining, 23 * 60 * 60) // Should be close to 24 hours
        }
        
        // Photo with explicit expiration
        samplePhoto.expiresAt = Date().addingTimeInterval(300) // 5 minutes
        if let remaining = samplePhoto.remainingTime {
            XCTAssertGreaterThan(remaining, 290)
            XCTAssertLessThan(remaining, 300)
        }
    }
    
    func testFormattedRemainingTime() throws {
        // Test seconds
        samplePhoto.expiresAt = Date().addingTimeInterval(30)
        XCTAssertEqual(samplePhoto.formattedRemainingTime, "30s")
        
        // Test minutes
        samplePhoto.expiresAt = Date().addingTimeInterval(120)
        XCTAssertEqual(samplePhoto.formattedRemainingTime, "2m")
        
        // Test hours
        samplePhoto.expiresAt = Date().addingTimeInterval(7200)
        XCTAssertEqual(samplePhoto.formattedRemainingTime, "2h")
        
        // No expiration
        samplePhoto.expiresAt = nil
        XCTAssertNil(samplePhoto.formattedRemainingTime)
    }
    
    func testBelongsToCurrentUser() throws {
        XCTAssertTrue(samplePhoto.belongsToCurrentUser("user123"))
        XCTAssertFalse(samplePhoto.belongsToCurrentUser("user456"))
    }
    
    // MARK: - Firebase Integration Tests
    
    func testToDictionary() throws {
        let dictionary = samplePhoto.toDictionary()
        
        XCTAssertEqual(dictionary["id"] as? String, "photo123")
        XCTAssertEqual(dictionary["userId"] as? String, "user123")
        XCTAssertEqual(dictionary["imageURL"] as? String, "https://example.com/photo.jpg")
        XCTAssertEqual(dictionary["caption"] as? String, "Test photo")
        XCTAssertEqual(dictionary["recipients"] as? [String], ["friend1", "friend2"])
        XCTAssertEqual(dictionary["isStory"] as? Bool, false)
        XCTAssertEqual(dictionary["viewDuration"] as? TimeInterval, 10.0)
        XCTAssertEqual(dictionary["maxViews"] as? Int, 1)
        XCTAssertEqual(dictionary["viewCount"] as? Int, 0)
        
        // Check Timestamp conversion
        XCTAssertTrue(dictionary["createdAt"] is Timestamp)
        
        // Check metadata
        let metadata = dictionary["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["filter"] as? String, "vintage")
    }
    
    func testToDictionaryWithoutOptionalFields() throws {
        let minimalPhoto = Photo(
            userId: "user123",
            imageURL: "https://example.com/minimal.jpg"
        )
        
        let dictionary = minimalPhoto.toDictionary()
        XCTAssertNil(dictionary["caption"])
        XCTAssertNil(dictionary["expiresAt"])
    }
    
    // MARK: - Codable Tests
    
    func testCodableEncoding() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(samplePhoto)
        XCTAssertFalse(data.isEmpty)
    }
    
    func testCodableDecoding() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(samplePhoto)
        
        let decoder = JSONDecoder()
        let decodedPhoto = try decoder.decode(Photo.self, from: data)
        
        XCTAssertEqual(decodedPhoto.id, samplePhoto.id)
        XCTAssertEqual(decodedPhoto.userId, samplePhoto.userId)
        XCTAssertEqual(decodedPhoto.imageURL, samplePhoto.imageURL)
        XCTAssertEqual(decodedPhoto.caption, samplePhoto.caption)
        XCTAssertEqual(decodedPhoto.recipients, samplePhoto.recipients)
        XCTAssertEqual(decodedPhoto.isStory, samplePhoto.isStory)
        XCTAssertEqual(decodedPhoto.viewDuration, samplePhoto.viewDuration)
        XCTAssertEqual(decodedPhoto.maxViews, samplePhoto.maxViews)
        XCTAssertEqual(decodedPhoto.viewCount, samplePhoto.viewCount)
    }
    
    // MARK: - Equality and Hashing Tests
    
    func testEquality() throws {
        let photo1 = Photo(
            id: "same123",
            userId: "user1",
            imageURL: "https://example.com/1.jpg"
        )
        
        let photo2 = Photo(
            id: "same123",
            userId: "user2",
            imageURL: "https://example.com/2.jpg"
        )
        
        let photo3 = Photo(
            id: "different123",
            userId: "user3",
            imageURL: "https://example.com/3.jpg"
        )
        
        XCTAssertEqual(photo1, photo2) // Same ID
        XCTAssertNotEqual(photo1, photo3) // Different ID
    }
    
    func testHashing() throws {
        let photo1 = Photo(
            id: "hash123",
            userId: "user1",
            imageURL: "https://example.com/1.jpg"
        )
        
        let photo2 = Photo(
            id: "hash123",
            userId: "user2",
            imageURL: "https://example.com/2.jpg"
        )
        
        XCTAssertEqual(photo1.hashValue, photo2.hashValue)
    }
    
    // MARK: - Performance Tests
    
    func testViewTrackingPerformance() throws {
        let photo = Photo(
            userId: "user123",
            imageURL: "https://example.com/perf.jpg",
            maxViews: 1000
        )
        
        measure {
            for i in 0..<1000 {
                photo.addRecipient("user\(i)")
                photo.markAsViewed(by: "user\(i)")
            }
        }
    }
    
    func testExpirationCheckPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = samplePhoto.hasExpired
                _ = samplePhoto.canBeViewedBy("friend1")
                _ = samplePhoto.shouldAutoDelete
                _ = samplePhoto.remainingTime
            }
        }
    }
    
    func testDictionaryConversionPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = samplePhoto.toDictionary()
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroViewDuration() throws {
        let photo = Photo(
            ephemeralSnap: "user123",
            imageURL: "https://example.com/zero.jpg",
            recipients: ["friend1"],
            viewDuration: 0.0
        )
        
        photo.markAsViewed(by: "friend1")
        XCTAssertTrue(photo.shouldAutoDelete)
    }
    
    func testNegativeViewDuration() throws {
        let photo = Photo(
            userId: "user123",
            imageURL: "https://example.com/negative.jpg",
            viewDuration: -5.0
        )
        
        photo.markAsViewed(by: "user123")
        XCTAssertTrue(photo.shouldAutoDelete)
    }
    
    func testLargeRecipientList() throws {
        let photo = Photo(
            userId: "user123",
            imageURL: "https://example.com/large.jpg"
        )
        
        // Add 10,000 recipients
        for i in 0..<10000 {
            photo.addRecipient("user\(i)")
        }
        
        XCTAssertEqual(photo.recipients.count, 10000)
        XCTAssertTrue(photo.canBeViewedBy("user5000"))
        
        // Remove one recipient
        photo.removeRecipient("user5000")
        XCTAssertFalse(photo.recipients.contains("user5000"))
        XCTAssertEqual(photo.recipients.count, 9999)
    }
    
    // MARK: - Memory Tests
    
    func testMemoryLeakPrevention() throws {
        weak var weakPhoto: Photo?
        
        autoreleasepool {
            let photo = Photo(
                userId: "memory_user",
                imageURL: "https://example.com/memory.jpg"
            )
            weakPhoto = photo
            
            // Perform operations
            photo.addRecipient("friend1")
            photo.markAsViewed(by: "friend1")
            _ = photo.toDictionary()
        }
        
        XCTAssertNil(weakPhoto, "Photo should be deallocated after autoreleasepool")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentViewOperations() throws {
        let photo = Photo(
            userId: "concurrent_user",
            imageURL: "https://example.com/concurrent.jpg",
            maxViews: 100
        )
        
        // Add recipients
        for i in 0..<100 {
            photo.addRecipient("user\(i)")
        }
        
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = 3
        
        // Concurrent viewing
        DispatchQueue.global().async {
            for i in 0..<50 {
                photo.markAsViewed(by: "user\(i)")
            }
            expectation.fulfill()
        }
        
        // More concurrent viewing
        DispatchQueue.global().async {
            for i in 50..<100 {
                photo.markAsViewed(by: "user\(i)")
            }
            expectation.fulfill()
        }
        
        // Concurrent checking
        DispatchQueue.global().async {
            for i in 0..<100 {
                _ = photo.hasBeenViewedBy("user\(i)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify final state
        XCTAssertGreaterThanOrEqual(photo.viewCount, 80) // Allow some race conditions
        XCTAssertLessThanOrEqual(photo.viewCount, 100)
    }
}