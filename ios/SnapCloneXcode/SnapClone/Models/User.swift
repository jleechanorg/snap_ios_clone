//
//  User.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Core User model with friend management and Firebase integration
//  Requirements: iOS 16+, Firebase SDK
//

import Foundation
import FirebaseFirestore

/// Represents a user in the SnapClone application
/// Conforms to Codable for Firebase integration and Identifiable for SwiftUI
@objc(User)
final class User: NSObject, Codable, Identifiable, ObservableObject {
    
    // MARK: - Properties
    
    /// Unique identifier for the user (matches Firebase Auth UID)
    var id: String
    
    /// Unique username for the user
    @Published var username: String
    
    /// User's email address
    @Published var email: String
    
    /// Display name shown to other users
    @Published var displayName: String
    
    /// Optional profile image URL from Firebase Storage
    @Published var profileImageURL: String?
    
    /// Array of friend user IDs
    @Published var friends: [String]
    
    /// Account creation timestamp
    let createdAt: Date
    
    /// Last time the user was active
    @Published var lastActive: Date
    
    /// Whether the user is currently online
    @Published var isOnline: Bool
    
    // MARK: - Coding Keys
    
    private enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case displayName
        case profileImageURL
        case friends
        case createdAt
        case lastActive
        case isOnline
    }
    
    // MARK: - Initializers
    
    /// Initialize a new user
    /// - Parameters:
    ///   - id: Unique user identifier
    ///   - username: Unique username
    ///   - email: User's email address
    ///   - displayName: Display name for the user
    ///   - profileImageURL: Optional profile image URL
    ///   - friends: Array of friend user IDs
    ///   - createdAt: Account creation date
    ///   - lastActive: Last activity date
    ///   - isOnline: Current online status
    init(id: String,
         username: String,
         email: String,
         displayName: String,
         profileImageURL: String? = nil,
         friends: [String] = [],
         createdAt: Date = Date(),
         lastActive: Date = Date(),
         isOnline: Bool = false) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.friends = friends
        self.createdAt = createdAt
        self.lastActive = lastActive
        self.isOnline = isOnline
        super.init()
    }
    
    // MARK: - Codable Implementation
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        friends = try container.decodeIfPresent([String].self, forKey: .friends) ?? []
        
        // Handle date decoding from Firestore Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastActive) {
            lastActive = timestamp.dateValue()
        } else {
            lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive) ?? Date()
        }
        
        isOnline = try container.decodeIfPresent(Bool.self, forKey: .isOnline) ?? false
        
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encode(friends, forKey: .friends)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastActive, forKey: .lastActive)
        try container.encode(isOnline, forKey: .isOnline)
    }
    
    // MARK: - Friend Management
    
    /// Add a friend to the user's friend list
    /// - Parameter friendId: The user ID to add as a friend
    /// - Returns: True if the friend was added, false if already a friend
    @discardableResult
    func addFriend(_ friendId: String) -> Bool {
        guard friendId != id && !friends.contains(friendId) else {
            return false
        }
        
        friends.append(friendId)
        return true
    }
    
    /// Remove a friend from the user's friend list
    /// - Parameter friendId: The user ID to remove from friends
    /// - Returns: True if the friend was removed, false if not found
    @discardableResult
    func removeFriend(_ friendId: String) -> Bool {
        guard let index = friends.firstIndex(of: friendId) else {
            return false
        }
        
        friends.remove(at: index)
        return true
    }
    
    /// Check if a user is a friend
    /// - Parameter userId: The user ID to check
    /// - Returns: True if the user is a friend
    func isFriend(_ userId: String) -> Bool {
        return friends.contains(userId)
    }
    
    /// Get the number of friends
    var friendCount: Int {
        return friends.count
    }
    
    // MARK: - Firebase Integration
    
    /// Convert user to dictionary for Firebase storage
    /// - Returns: Dictionary representation for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "username": username,
            "email": email,
            "displayName": displayName,
            "friends": friends,
            "createdAt": Timestamp(date: createdAt),
            "lastActive": Timestamp(date: lastActive),
            "isOnline": isOnline
        ]
        
        if let profileImageURL = profileImageURL {
            dict["profileImageURL"] = profileImageURL
        }
        
        return dict
    }
    
    /// Create user from Firestore document snapshot
    /// - Parameter document: Firestore document snapshot
    /// - Returns: User instance or nil if parsing fails
    static func from(document: DocumentSnapshot) -> User? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let username = data["username"] as? String,
              let email = data["email"] as? String,
              let displayName = data["displayName"] as? String else {
            return nil
        }
        
        let profileImageURL = data["profileImageURL"] as? String
        let friends = data["friends"] as? [String] ?? []
        let isOnline = data["isOnline"] as? Bool ?? false
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let lastActive: Date
        if let timestamp = data["lastActive"] as? Timestamp {
            lastActive = timestamp.dateValue()
        } else {
            lastActive = Date()
        }
        
        return User(
            id: id,
            username: username,
            email: email,
            displayName: displayName,
            profileImageURL: profileImageURL,
            friends: friends,
            createdAt: createdAt,
            lastActive: lastActive,
            isOnline: isOnline
        )
    }
    
    // MARK: - Utility Methods
    
    /// Update the user's last active timestamp
    func updateLastActive() {
        lastActive = Date()
    }
    
    /// Set the user's online status
    /// - Parameter isOnline: New online status
    func setOnlineStatus(_ isOnline: Bool) {
        self.isOnline = isOnline
        if isOnline {
            updateLastActive()
        }
    }
    
    // MARK: - Equatable & Hashable
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    override var hash: Int {
        return id.hashValue
    }
}

// MARK: - User Extensions

extension User {
    /// Returns a formatted string for the user's last active time
    var lastActiveFormatted: String {
        let formatter = DateFormatter()
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastActive)
        
        if timeInterval < 60 {
            return "Active now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: lastActive)
        }
    }
}

// MARK: - UserSearchResult

/// Represents a user search result for friend discovery
struct UserSearchResult: Identifiable, Codable {
    let id: String
    let username: String
    let displayName: String
    let profileImageURL: String?
    let isOnline: Bool
    let lastActive: Date
    
    /// Initialize from User model
    init(from user: User) {
        self.id = user.id
        self.username = user.username
        self.displayName = user.displayName
        self.profileImageURL = user.profileImageURL
        self.isOnline = user.isOnline
        self.lastActive = user.lastActive
    }
}

// MARK: - Mock Data
extension User {
    static var mockFriends: [User] {
        return [
            User(
                id: "friend1",
                username: "john_doe",
                email: "john@example.com",
                displayName: "John Doe",
                isOnline: true
            ),
            User(
                id: "friend2",
                username: "jane_smith", 
                email: "jane@example.com",
                displayName: "Jane Smith",
                isOnline: false
            ),
            User(
                id: "friend3",
                username: "mike_j",
                email: "mike@example.com",
                displayName: "Mike Johnson",
                isOnline: true
            ),
            User(
                id: "friend4",
                username: "sarah_w",
                email: "sarah@example.com",
                displayName: "Sarah Wilson",
                isOnline: false
            ),
            User(
                id: "friend5",
                username: "alex_brown",
                email: "alex@example.com", 
                displayName: "Alex Brown",
                isOnline: true
            )
        ]
    }
}