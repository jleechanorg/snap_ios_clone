//
//  FriendTests.swift
//  SnapCloneTests
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Comprehensive tests for Friend model and relationship validation
//

import XCTest
import FirebaseFirestore
@testable import SnapClone

final class FriendTests: XCTestCase {
    
    // MARK: - Properties
    
    var user1: User!
    var user2: User!
    var user3: User!
    
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
        
        user3 = User(
            id: "user3",
            username: "testuser3",
            email: "test3@example.com",
            displayName: "Test User 3"
        )
    }
    
    override func tearDownWithError() throws {
        user1 = nil
        user2 = nil
        user3 = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Friend Addition Tests
    
    func testAddFriend() throws {
        // Test adding a valid friend
        let result = user1.addFriend(user2.id)
        XCTAssertTrue(result)
        XCTAssertTrue(user1.isFriend(user2.id))
        XCTAssertEqual(user1.friendCount, 1)
    }
    
    func testAddSelfAsFriend() throws {
        // Should not be able to add self as friend
        let result = user1.addFriend(user1.id)
        XCTAssertFalse(result)
        XCTAssertFalse(user1.isFriend(user1.id))
        XCTAssertEqual(user1.friendCount, 0)
    }
    
    func testAddDuplicateFriend() throws {
        // Add friend first time
        user1.addFriend(user2.id)
        XCTAssertEqual(user1.friendCount, 1)
        
        // Try to add same friend again
        let result = user1.addFriend(user2.id)
        XCTAssertFalse(result)
        XCTAssertEqual(user1.friendCount, 1) // Should remain 1
    }
    
    func testAddMultipleFriends() throws {
        user1.addFriend(user2.id)
        user1.addFriend(user3.id)
        
        XCTAssertEqual(user1.friendCount, 2)
        XCTAssertTrue(user1.isFriend(user2.id))
        XCTAssertTrue(user1.isFriend(user3.id))
    }
    
    // MARK: - Friend Removal Tests
    
    func testRemoveFriend() throws {
        // Add and then remove friend
        user1.addFriend(user2.id)
        XCTAssertTrue(user1.isFriend(user2.id))
        
        let result = user1.removeFriend(user2.id)
        XCTAssertTrue(result)
        XCTAssertFalse(user1.isFriend(user2.id))
        XCTAssertEqual(user1.friendCount, 0)
    }
    
    func testRemoveNonExistentFriend() throws {
        // Try to remove friend that was never added
        let result = user1.removeFriend(user2.id)
        XCTAssertFalse(result)
        XCTAssertEqual(user1.friendCount, 0)
    }
    
    func testRemoveOneOfMultipleFriends() throws {
        // Add multiple friends
        user1.addFriend(user2.id)
        user1.addFriend(user3.id)
        XCTAssertEqual(user1.friendCount, 2)
        
        // Remove one friend
        user1.removeFriend(user2.id)
        XCTAssertFalse(user1.isFriend(user2.id))
        XCTAssertTrue(user1.isFriend(user3.id))
        XCTAssertEqual(user1.friendCount, 1)
    }
    
    // MARK: - Friend Query Tests
    
    func testIsFriend() throws {
        XCTAssertFalse(user1.isFriend(user2.id))
        
        user1.addFriend(user2.id)
        XCTAssertTrue(user1.isFriend(user2.id))
        XCTAssertFalse(user1.isFriend(user3.id))
    }
    
    func testFriendCount() throws {
        XCTAssertEqual(user1.friendCount, 0)
        
        user1.addFriend(user2.id)
        XCTAssertEqual(user1.friendCount, 1)
        
        user1.addFriend(user3.id)
        XCTAssertEqual(user1.friendCount, 2)
        
        user1.removeFriend(user2.id)
        XCTAssertEqual(user1.friendCount, 1)
    }
    
    // MARK: - Bidirectional Friendship Tests
    
    func testBidirectionalFriendship() throws {
        // Both users should add each other as friends
        user1.addFriend(user2.id)
        user2.addFriend(user1.id)
        
        XCTAssertTrue(user1.isFriend(user2.id))
        XCTAssertTrue(user2.isFriend(user1.id))
    }
    
    func testUnidirectionalFriendship() throws {
        // Only one user adds the other as friend
        user1.addFriend(user2.id)
        
        XCTAssertTrue(user1.isFriend(user2.id))
        XCTAssertFalse(user2.isFriend(user1.id))
    }
    
    func testRemoveBidirectionalFriendship() throws {
        // Add bidirectional friendship
        user1.addFriend(user2.id)
        user2.addFriend(user1.id)
        
        // Remove from one side
        user1.removeFriend(user2.id)
        
        XCTAssertFalse(user1.isFriend(user2.id))
        XCTAssertTrue(user2.isFriend(user1.id)) // Other side should remain
    }
    
    // MARK: - Friend List Management Tests
    
    func testFriendsArray() throws {
        user1.addFriend(user2.id)
        user1.addFriend(user3.id)
        
        XCTAssertEqual(user1.friends.count, 2)
        XCTAssertTrue(user1.friends.contains(user2.id))
        XCTAssertTrue(user1.friends.contains(user3.id))
    }
    
    func testFriendsArrayOrder() throws {
        user1.addFriend(user2.id)
        user1.addFriend(user3.id)
        
        // Friends should be added in order
        XCTAssertEqual(user1.friends[0], user2.id)
        XCTAssertEqual(user1.friends[1], user3.id)
    }
    
    func testFriendsArrayAfterRemoval() throws {
        user1.addFriend(user2.id)
        user1.addFriend(user3.id)
        user1.removeFriend(user2.id)
        
        XCTAssertEqual(user1.friends.count, 1)
        XCTAssertEqual(user1.friends[0], user3.id)
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyStringFriendId() throws {
        let result = user1.addFriend("")
        XCTAssertFalse(result)
        XCTAssertEqual(user1.friendCount, 0)
    }
    
    func testWhitespaceOnlyFriendId() throws {
        let result = user1.addFriend("   ")
        XCTAssertFalse(result) // Assuming validation rejects whitespace-only IDs
        XCTAssertEqual(user1.friendCount, 0)
    }
    
    func testVeryLongFriendId() throws {
        let longId = String(repeating: "a", count: 10000)
        let result = user1.addFriend(longId)
        XCTAssertTrue(result) // Should handle long IDs
        XCTAssertTrue(user1.isFriend(longId))
    }
    
    func testSpecialCharactersFriendId() throws {
        let specialId = "user@#$%^&*()_+-={}[]|\\:;\"'<>?,./"
        let result = user1.addFriend(specialId)
        XCTAssertTrue(result) // Should handle special characters
        XCTAssertTrue(user1.isFriend(specialId))
    }
    
    // MARK: - Performance Tests
    
    func testLargeFriendsList() throws {
        // Add 10,000 friends
        for i in 0..<10000 {
            user1.addFriend("friend\(i)")
        }
        
        XCTAssertEqual(user1.friendCount, 10000)
        XCTAssertTrue(user1.isFriend("friend5000"))
        XCTAssertFalse(user1.isFriend("friend10000"))
    }
    
    func testFriendOperationsPerformance() throws {
        measure {
            // Add 1000 friends
            for i in 0..<1000 {
                user1.addFriend("friend\(i)")
            }
            
            // Check if friends exist
            for i in 0..<1000 {
                _ = user1.isFriend("friend\(i)")
            }
            
            // Remove 500 friends
            for i in 0..<500 {
                user1.removeFriend("friend\(i)")
            }
        }
    }
    
    func testFriendSearchPerformance() throws {
        // Add many friends
        for i in 0..<10000 {
            user1.addFriend("friend\(i)")
        }
        
        measure {
            // Search for specific friends
            for i in 0..<1000 {
                _ = user1.isFriend("friend\(i * 10)")
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testFriendListMemoryManagement() throws {
        weak var weakUser: User?
        
        autoreleasepool {
            let tempUser = User(
                id: "memory_test",
                username: "memoryuser",
                email: "memory@example.com",
                displayName: "Memory User"
            )
            weakUser = tempUser
            
            // Add many friends
            for i in 0..<1000 {
                tempUser.addFriend("friend\(i)")
            }
            
            // Perform operations
            _ = tempUser.friendCount
            _ = tempUser.isFriend("friend500")
        }
        
        XCTAssertNil(weakUser, "User should be deallocated after autoreleasepool")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentFriendOperations() throws {
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = 3
        
        // Concurrent adding
        DispatchQueue.global().async {
            for i in 0..<1000 {
                self.user1.addFriend("concurrent_a_\(i)")
            }
            expectation.fulfill()
        }
        
        // More concurrent adding
        DispatchQueue.global().async {
            for i in 0..<1000 {
                self.user1.addFriend("concurrent_b_\(i)")
            }
            expectation.fulfill()
        }
        
        // Concurrent checking
        DispatchQueue.global().async {
            for i in 0..<1000 {
                _ = self.user1.isFriend("concurrent_a_\(i)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify final state (allowing for race conditions)
        XCTAssertGreaterThanOrEqual(user1.friendCount, 1500)
        XCTAssertLessThanOrEqual(user1.friendCount, 2000)
    }
    
    func testConcurrentAddRemoveOperations() throws {
        // Pre-populate with friends
        for i in 0..<1000 {
            user1.addFriend("preloaded_\(i)")
        }
        
        let expectation = XCTestExpectation(description: "Concurrent add/remove completed")
        expectation.expectedFulfillmentCount = 2
        
        // Concurrent removing
        DispatchQueue.global().async {
            for i in 0..<500 {
                self.user1.removeFriend("preloaded_\(i)")
            }
            expectation.fulfill()
        }
        
        // Concurrent adding new friends
        DispatchQueue.global().async {
            for i in 0..<500 {
                self.user1.addFriend("new_friend_\(i)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify reasonable final state
        XCTAssertGreaterThanOrEqual(user1.friendCount, 750)
        XCTAssertLessThanOrEqual(user1.friendCount, 1500)
    }
    
    // MARK: - Friend Relationship Validation Tests
    
    func testFriendshipConsistency() throws {
        // Add multiple friends and verify consistency
        let friendIds = ["friend1", "friend2", "friend3", "friend4", "friend5"]
        
        for friendId in friendIds {
            user1.addFriend(friendId)
        }
        
        // Verify all friends are present
        for friendId in friendIds {
            XCTAssertTrue(user1.isFriend(friendId))
        }
        
        XCTAssertEqual(user1.friendCount, friendIds.count)
        XCTAssertEqual(Set(user1.friends), Set(friendIds))
    }
    
    func testFriendshipAfterMultipleOperations() throws {
        // Complex sequence of operations
        user1.addFriend("friend1")
        user1.addFriend("friend2")
        user1.addFriend("friend3")
        
        user1.removeFriend("friend2")
        user1.addFriend("friend4")
        user1.removeFriend("friend1")
        user1.addFriend("friend5")
        
        // Final state verification
        XCTAssertFalse(user1.isFriend("friend1"))
        XCTAssertFalse(user1.isFriend("friend2"))
        XCTAssertTrue(user1.isFriend("friend3"))
        XCTAssertTrue(user1.isFriend("friend4"))
        XCTAssertTrue(user1.isFriend("friend5"))
        XCTAssertEqual(user1.friendCount, 3)
    }
    
    // MARK: - Network Simulation Tests
    
    func testFriendNetworkSimulation() throws {
        // Create a network of users
        var users: [User] = []
        for i in 0..<10 {
            let user = User(
                id: "network_user_\(i)",
                username: "networkuser\(i)",
                email: "network\(i)@example.com",
                displayName: "Network User \(i)"
            )
            users.append(user)
        }
        
        // Create random friendships
        for i in 0..<users.count {
            for j in (i+1)..<users.count {
                if Int.random(in: 0...1) == 1 { // 50% chance of friendship
                    users[i].addFriend(users[j].id)
                    users[j].addFriend(users[i].id)
                }
            }
        }
        
        // Verify network properties
        let totalFriendships = users.reduce(0) { $0 + $1.friendCount }
        XCTAssertGreaterThan(totalFriendships, 0)
        
        // Check for mutual friendships
        for i in 0..<users.count {
            for friendId in users[i].friends {
                if let friendIndex = users.firstIndex(where: { $0.id == friendId }) {
                    // If A is friend of B, check if B is friend of A
                    if users[friendIndex].isFriend(users[i].id) {
                        XCTAssertTrue(users[i].isFriend(friendId))
                    }
                }
            }
        }
    }
}