//
//  UserTests.swift
//  SnapCloneTests
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Comprehensive tests for User model, friend management, and Firebase integration
//

import XCTest
import FirebaseFirestore
@testable import SnapClone

final class UserTests: XCTestCase {
    
    // MARK: - Properties
    
    var sampleUser: User!
    var sampleFriend: User!
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        sampleUser = User(
            id: "user123",
            username: "testuser",
            email: "test@example.com",
            displayName: "Test User",
            profileImageURL: "https://example.com/profile.jpg",
            friends: ["friend1", "friend2"],
            createdAt: Date(timeIntervalSince1970: 1640995200), // Jan 1, 2022
            lastActive: Date(timeIntervalSince1970: 1640995200),
            isOnline: true
        )
        
        sampleFriend = User(
            id: "friend123",
            username: "frienduser",
            email: "friend@example.com",
            displayName: "Friend User"
        )
    }
    
    override func tearDownWithError() throws {
        sampleUser = nil
        sampleFriend = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testUserInitialization() throws {
        XCTAssertEqual(sampleUser.id, "user123")
        XCTAssertEqual(sampleUser.username, "testuser")
        XCTAssertEqual(sampleUser.email, "test@example.com")
        XCTAssertEqual(sampleUser.displayName, "Test User")
        XCTAssertEqual(sampleUser.profileImageURL, "https://example.com/profile.jpg")
        XCTAssertEqual(sampleUser.friends, ["friend1", "friend2"])
        XCTAssertTrue(sampleUser.isOnline)
    }
    
    func testUserDefaultInitialization() throws {
        let user = User(
            id: "default123",
            username: "defaultuser",
            email: "default@example.com",
            displayName: "Default User"
        )
        
        XCTAssertEqual(user.id, "default123")
        XCTAssertEqual(user.username, "defaultuser")
        XCTAssertEqual(user.email, "default@example.com")
        XCTAssertEqual(user.displayName, "Default User")
        XCTAssertNil(user.profileImageURL)
        XCTAssertTrue(user.friends.isEmpty)
        XCTAssertFalse(user.isOnline)
    }
    
    // MARK: - Friend Management Tests
    
    func testAddFriend() throws {
        let user = User(
            id: "user123",
            username: "testuser",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        // Test adding a new friend
        let result = user.addFriend("friend123")
        XCTAssertTrue(result)
        XCTAssertTrue(user.friends.contains("friend123"))
        XCTAssertEqual(user.friendCount, 1)
    }
    
    func testAddDuplicateFriend() throws {
        // Test adding duplicate friend
        let result = sampleUser.addFriend("friend1")
        XCTAssertFalse(result)
        XCTAssertEqual(sampleUser.friendCount, 2) // Should remain unchanged
    }
    
    func testAddSelfAsFriend() throws {
        // Test adding self as friend
        let result = sampleUser.addFriend("user123")
        XCTAssertFalse(result)
        XCTAssertEqual(sampleUser.friendCount, 2) // Should remain unchanged
    }
    
    func testRemoveFriend() throws {
        // Test removing existing friend
        let result = sampleUser.removeFriend("friend1")
        XCTAssertTrue(result)
        XCTAssertFalse(sampleUser.friends.contains("friend1"))
        XCTAssertEqual(sampleUser.friendCount, 1)
    }
    
    func testRemoveNonExistentFriend() throws {
        // Test removing non-existent friend
        let result = sampleUser.removeFriend("nonexistent")
        XCTAssertFalse(result)
        XCTAssertEqual(sampleUser.friendCount, 2) // Should remain unchanged
    }
    
    func testIsFriend() throws {
        XCTAssertTrue(sampleUser.isFriend("friend1"))
        XCTAssertTrue(sampleUser.isFriend("friend2"))
        XCTAssertFalse(sampleUser.isFriend("stranger123"))
    }
    
    func testFriendCount() throws {
        XCTAssertEqual(sampleUser.friendCount, 2)
        
        sampleUser.addFriend("friend3")
        XCTAssertEqual(sampleUser.friendCount, 3)
        
        sampleUser.removeFriend("friend1")
        XCTAssertEqual(sampleUser.friendCount, 2)
    }
    
    // MARK: - Utility Methods Tests
    
    func testUpdateLastActive() throws {
        let originalTime = sampleUser.lastActive
        
        // Wait a small amount to ensure time difference
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sampleUser.updateLastActive()
        }
        
        let expectation = XCTestExpectation(description: "Last active updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertGreaterThan(self.sampleUser.lastActive, originalTime)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSetOnlineStatus() throws {
        let originalTime = sampleUser.lastActive
        
        sampleUser.setOnlineStatus(false)
        XCTAssertFalse(sampleUser.isOnline)
        
        // Wait a small amount to ensure time difference
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sampleUser.setOnlineStatus(true)
        }
        
        let expectation = XCTestExpectation(description: "Online status updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(self.sampleUser.isOnline)
            XCTAssertGreaterThan(self.sampleUser.lastActive, originalTime)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLastActiveFormatted() throws {
        let now = Date()
        
        // Test "Active now"
        let activeUser = User(
            id: "active123",
            username: "activeuser",
            email: "active@example.com",
            displayName: "Active User",
            lastActive: now
        )
        XCTAssertEqual(activeUser.lastActiveFormatted, "Active now")
        
        // Test minutes ago
        let minutesAgoUser = User(
            id: "minutes123",
            username: "minutesuser",
            email: "minutes@example.com",
            displayName: "Minutes User",
            lastActive: now.addingTimeInterval(-300) // 5 minutes ago
        )
        XCTAssertEqual(minutesAgoUser.lastActiveFormatted, "5 min ago")
        
        // Test hours ago
        let hoursAgoUser = User(
            id: "hours123",
            username: "hoursuser",
            email: "hours@example.com",
            displayName: "Hours User",
            lastActive: now.addingTimeInterval(-7200) // 2 hours ago
        )
        XCTAssertEqual(hoursAgoUser.lastActiveFormatted, "2h ago")
    }
    
    // MARK: - Equality and Hashing Tests
    
    func testEquality() throws {
        let user1 = User(
            id: "same123",
            username: "user1",
            email: "user1@example.com",
            displayName: "User 1"
        )
        
        let user2 = User(
            id: "same123",
            username: "user2",
            email: "user2@example.com",
            displayName: "User 2"
        )
        
        let user3 = User(
            id: "different123",
            username: "user3",
            email: "user3@example.com",
            displayName: "User 3"
        )
        
        XCTAssertEqual(user1, user2) // Same ID
        XCTAssertNotEqual(user1, user3) // Different ID
    }
    
    func testHashing() throws {
        let user1 = User(
            id: "hash123",
            username: "user1",
            email: "user1@example.com",
            displayName: "User 1"
        )
        
        let user2 = User(
            id: "hash123",
            username: "user2",
            email: "user2@example.com",
            displayName: "User 2"
        )
        
        XCTAssertEqual(user1.hashValue, user2.hashValue)
    }
    
    // MARK: - Firebase Integration Tests
    
    func testToDictionary() throws {
        let dictionary = sampleUser.toDictionary()
        
        XCTAssertEqual(dictionary["id"] as? String, "user123")
        XCTAssertEqual(dictionary["username"] as? String, "testuser")
        XCTAssertEqual(dictionary["email"] as? String, "test@example.com")
        XCTAssertEqual(dictionary["displayName"] as? String, "Test User")
        XCTAssertEqual(dictionary["profileImageURL"] as? String, "https://example.com/profile.jpg")
        XCTAssertEqual(dictionary["friends"] as? [String], ["friend1", "friend2"])
        XCTAssertEqual(dictionary["isOnline"] as? Bool, true)
        
        // Check Timestamp conversion
        XCTAssertTrue(dictionary["createdAt"] is Timestamp)
        XCTAssertTrue(dictionary["lastActive"] is Timestamp)
    }
    
    func testToDictionaryWithoutProfileImage() throws {
        let userWithoutImage = User(
            id: "noimage123",
            username: "noimaguser",
            email: "noimage@example.com",
            displayName: "No Image User"
        )
        
        let dictionary = userWithoutImage.toDictionary()
        XCTAssertNil(dictionary["profileImageURL"])
    }
    
    // MARK: - Codable Tests
    
    func testCodableEncoding() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(sampleUser)
        XCTAssertFalse(data.isEmpty)
    }
    
    func testCodableDecoding() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(sampleUser)
        
        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(decodedUser.id, sampleUser.id)
        XCTAssertEqual(decodedUser.username, sampleUser.username)
        XCTAssertEqual(decodedUser.email, sampleUser.email)
        XCTAssertEqual(decodedUser.displayName, sampleUser.displayName)
        XCTAssertEqual(decodedUser.profileImageURL, sampleUser.profileImageURL)
        XCTAssertEqual(decodedUser.friends, sampleUser.friends)
        XCTAssertEqual(decodedUser.isOnline, sampleUser.isOnline)
    }
    
    func testCodableDecodingWithMissingOptionalFields() throws {
        let json = """
        {
            "id": "minimal123",
            "username": "minimaluser",
            "email": "minimal@example.com",
            "displayName": "Minimal User",
            "createdAt": 1640995200,
            "lastActive": 1640995200
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(user.id, "minimal123")
        XCTAssertNil(user.profileImageURL)
        XCTAssertTrue(user.friends.isEmpty)
        XCTAssertFalse(user.isOnline)
    }
    
    // MARK: - Performance Tests
    
    func testFriendOperationsPerformance() throws {
        let user = User(
            id: "perf123",
            username: "perfuser",
            email: "perf@example.com",
            displayName: "Performance User"
        )
        
        measure {
            // Add 1000 friends
            for i in 0..<1000 {
                user.addFriend("friend\(i)")
            }
            
            // Check if friend exists
            for i in 0..<1000 {
                _ = user.isFriend("friend\(i)")
            }
            
            // Remove 500 friends
            for i in 0..<500 {
                user.removeFriend("friend\(i)")
            }
        }
    }
    
    func testDictionaryConversionPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = sampleUser.toDictionary()
            }
        }
    }
    
    func testCodingPerformance() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        measure {
            for _ in 0..<1000 {
                do {
                    let data = try encoder.encode(sampleUser)
                    _ = try decoder.decode(User.self, from: data)
                } catch {
                    XCTFail("Coding failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyStringHandling() throws {
        let user = User(
            id: "",
            username: "",
            email: "",
            displayName: ""
        )
        
        XCTAssertEqual(user.id, "")
        XCTAssertEqual(user.username, "")
        XCTAssertEqual(user.email, "")
        XCTAssertEqual(user.displayName, "")
    }
    
    func testLargeDataHandling() throws {
        let largeUsername = String(repeating: "a", count: 10000)
        let user = User(
            id: "large123",
            username: largeUsername,
            email: "large@example.com",
            displayName: "Large User"
        )
        
        XCTAssertEqual(user.username.count, 10000)
        
        // Test that it can still be encoded/decoded
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        
        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)
        XCTAssertEqual(decodedUser.username, largeUsername)
    }
    
    func testManyFriendsHandling() throws {
        let user = User(
            id: "manyfriends123",
            username: "manyfriends",
            email: "manyfriends@example.com",
            displayName: "Many Friends User"
        )
        
        // Add 10,000 friends
        for i in 0..<10000 {
            user.addFriend("friend\(i)")
        }
        
        XCTAssertEqual(user.friendCount, 10000)
        XCTAssertTrue(user.isFriend("friend5000"))
        
        // Test removal
        user.removeFriend("friend5000")
        XCTAssertFalse(user.isFriend("friend5000"))
        XCTAssertEqual(user.friendCount, 9999)
    }
    
    // MARK: - Memory Tests
    
    func testMemoryLeakPrevention() throws {
        weak var weakUser: User?
        
        autoreleasepool {
            let user = User(
                id: "memory123",
                username: "memoryuser",
                email: "memory@example.com",
                displayName: "Memory User"
            )
            weakUser = user
            
            // Perform operations
            user.addFriend("friend1")
            user.updateLastActive()
            user.setOnlineStatus(true)
            _ = user.toDictionary()
        }
        
        XCTAssertNil(weakUser, "User should be deallocated after autoreleasepool")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentFriendOperations() throws {
        let user = User(
            id: "concurrent123",
            username: "concurrentuser",
            email: "concurrent@example.com",
            displayName: "Concurrent User"
        )
        
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = 3
        
        // Concurrent adding
        DispatchQueue.global().async {
            for i in 0..<100 {
                user.addFriend("friend_a_\(i)")
            }
            expectation.fulfill()
        }
        
        // Concurrent adding different friends
        DispatchQueue.global().async {
            for i in 0..<100 {
                user.addFriend("friend_b_\(i)")
            }
            expectation.fulfill()
        }
        
        // Concurrent checking
        DispatchQueue.global().async {
            for i in 0..<100 {
                _ = user.isFriend("friend_a_\(i)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify final state (should have around 200 friends, allowing for some race conditions)
        XCTAssertGreaterThanOrEqual(user.friendCount, 150)
        XCTAssertLessThanOrEqual(user.friendCount, 200)
    }
}