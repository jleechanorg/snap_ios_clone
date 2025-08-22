//
//  Photo.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Photo/Media model for ephemeral sharing and stories
//  Requirements: iOS 16+, Firebase SDK
//

import Foundation
import FirebaseFirestore

/// Represents a photo/media item in the SnapClone application
/// Supports ephemeral sharing and story functionality
@objc(Photo)
final class Photo: NSObject, Codable, Identifiable, ObservableObject {
    
    // MARK: - Properties
    
    /// Unique identifier for the photo
    let id: String
    
    /// ID of the user who created the photo
    let userId: String
    
    /// URL of the image in Firebase Storage
    @Published var imageURL: String
    
    /// Optional caption for the photo
    @Published var caption: String?
    
    /// Array of user IDs who can view this photo
    @Published var recipients: [String]
    
    /// Timestamp when the photo was created
    let createdAt: Date
    
    /// Optional expiration date for ephemeral photos
    @Published var expiresAt: Date?
    
    /// Array of user IDs who have viewed this photo
    @Published var viewedBy: [String]
    
    /// Whether this photo is part of a story
    @Published var isStory: Bool
    
    /// Duration the photo is visible when viewed (for ephemeral photos)
    let viewDuration: TimeInterval
    
    /// Maximum number of times the photo can be viewed
    let maxViews: Int
    
    /// Current view count
    @Published var viewCount: Int
    
    /// Additional metadata for the photo
    @Published var metadata: [String: Any]
    
    // MARK: - Coding Keys
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case imageURL
        case caption
        case recipients
        case createdAt
        case expiresAt
        case viewedBy
        case isStory
        case viewDuration
        case maxViews
        case viewCount
        case metadata
    }
    
    // MARK: - Initializers
    
    /// Initialize a new photo
    /// - Parameters:
    ///   - id: Unique photo identifier
    ///   - userId: ID of the user who created the photo
    ///   - imageURL: URL of the image
    ///   - caption: Optional caption
    ///   - recipients: Array of user IDs who can view the photo
    ///   - createdAt: Creation timestamp
    ///   - expiresAt: Optional expiration date
    ///   - viewedBy: Array of user IDs who have viewed the photo
    ///   - isStory: Whether this is a story photo
    ///   - viewDuration: View duration for ephemeral photos
    ///   - maxViews: Maximum number of views allowed
    ///   - viewCount: Current view count
    ///   - metadata: Additional metadata
    init(id: String = UUID().uuidString,
         userId: String,
         imageURL: String,
         caption: String? = nil,
         recipients: [String] = [],
         createdAt: Date = Date(),
         expiresAt: Date? = nil,
         viewedBy: [String] = [],
         isStory: Bool = false,
         viewDuration: TimeInterval = 10.0,
         maxViews: Int = 1,
         viewCount: Int = 0,
         metadata: [String: Any] = [:]) {
        self.id = id
        self.userId = userId
        self.imageURL = imageURL
        self.caption = caption
        self.recipients = recipients
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.viewedBy = viewedBy
        self.isStory = isStory
        self.viewDuration = viewDuration
        self.maxViews = maxViews
        self.viewCount = viewCount
        self.metadata = metadata
        super.init()
    }
    
    // MARK: - Codable Implementation
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        recipients = try container.decodeIfPresent([String].self, forKey: .recipients) ?? []
        
        // Handle date decoding from Firestore Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let expiresAtTimestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .expiresAt) {
            expiresAt = expiresAtTimestamp.dateValue()
        } else {
            expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        }
        
        viewedBy = try container.decodeIfPresent([String].self, forKey: .viewedBy) ?? []
        isStory = try container.decodeIfPresent(Bool.self, forKey: .isStory) ?? false
        viewDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .viewDuration) ?? 10.0
        maxViews = try container.decodeIfPresent(Int.self, forKey: .maxViews) ?? 1
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        // Metadata handling - skip for now as [String: Any] isn't Codable directly
        metadata = [:]
        
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(caption, forKey: .caption)
        try container.encode(recipients, forKey: .recipients)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encode(viewedBy, forKey: .viewedBy)
        try container.encode(isStory, forKey: .isStory)
        try container.encode(viewDuration, forKey: .viewDuration)
        try container.encode(maxViews, forKey: .maxViews)
        try container.encode(viewCount, forKey: .viewCount)
        // Note: metadata encoding may need custom handling for complex types
    }
    
    // MARK: - Photo Logic
    
    /// Check if the photo has expired
    /// - Returns: True if the photo has expired
    var hasExpired: Bool {
        guard let expiresAt = expiresAt else {
            // For stories, check if 24 hours have passed
            if isStory {
                let twentyFourHours: TimeInterval = 24 * 60 * 60
                return Date().timeIntervalSince(createdAt) > twentyFourHours
            }
            return false
        }
        return Date() > expiresAt
    }
    
    /// Check if the photo can be viewed by a specific user
    /// - Parameter userId: ID of the user to check
    /// - Returns: True if the user can view the photo
    func canBeViewedBy(_ userId: String) -> Bool {
        // Check if expired
        guard !hasExpired else { return false }
        
        // Check if max views reached
        guard viewCount < maxViews else { return false }
        
        // For stories, check if user is a friend
        if isStory {
            // Stories are generally visible to all friends
            return true
        }
        
        // For regular snaps, check if user is in recipients
        return recipients.contains(userId) || self.userId == userId
    }
    
    /// Mark the photo as viewed by a user
    /// - Parameter userId: ID of the user who viewed the photo
    /// - Returns: True if the view was recorded
    @discardableResult
    func markAsViewed(by userId: String) -> Bool {
        guard canBeViewedBy(userId) && !viewedBy.contains(userId) else {
            return false
        }
        
        viewedBy.append(userId)
        viewCount += 1
        
        // Set expiration for ephemeral photos if not already set
        if expiresAt == nil && !isStory {
            expiresAt = Date().addingTimeInterval(viewDuration)
        }
        
        return true
    }
    
    /// Check if a user has viewed this photo
    /// - Parameter userId: ID of the user to check
    /// - Returns: True if the user has viewed the photo
    func hasBeenViewedBy(_ userId: String) -> Bool {
        return viewedBy.contains(userId)
    }
    
    /// Get the number of unique views
    var uniqueViewCount: Int {
        return viewedBy.count
    }
    
    /// Check if this photo should be auto-deleted
    /// - Returns: True if the photo should be deleted
    var shouldAutoDelete: Bool {
        // Delete if expired
        if hasExpired {
            return true
        }
        
        // Delete if max views reached and all recipients have viewed
        if viewCount >= maxViews && !recipients.isEmpty {
            let allRecipientsViewed = recipients.allSatisfy { viewedBy.contains($0) }
            return allRecipientsViewed
        }
        
        return false
    }
    
    /// Add a recipient to the photo
    /// - Parameter userId: ID of the user to add as recipient
    /// - Returns: True if the recipient was added
    @discardableResult
    func addRecipient(_ userId: String) -> Bool {
        guard !recipients.contains(userId) && userId != self.userId else {
            return false
        }
        
        recipients.append(userId)
        return true
    }
    
    /// Remove a recipient from the photo
    /// - Parameter userId: ID of the user to remove
    /// - Returns: True if the recipient was removed
    @discardableResult
    func removeRecipient(_ userId: String) -> Bool {
        guard let index = recipients.firstIndex(of: userId) else {
            return false
        }
        
        recipients.remove(at: index)
        return true
    }
    
    // MARK: - Firebase Integration
    
    /// Convert photo to dictionary for Firebase storage
    /// - Returns: Dictionary representation for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "userId": userId,
            "imageURL": imageURL,
            "recipients": recipients,
            "createdAt": Timestamp(date: createdAt),
            "viewedBy": viewedBy,
            "isStory": isStory,
            "viewDuration": viewDuration,
            "maxViews": maxViews,
            "viewCount": viewCount
        ]
        
        if let caption = caption {
            dict["caption"] = caption
        }
        
        if let expiresAt = expiresAt {
            dict["expiresAt"] = Timestamp(date: expiresAt)
        }
        
        if !metadata.isEmpty {
            dict["metadata"] = metadata
        }
        
        return dict
    }
    
    /// Create photo from Firestore document snapshot
    /// - Parameter document: Firestore document snapshot
    /// - Returns: Photo instance or nil if parsing fails
    static func from(document: DocumentSnapshot) -> Photo? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let userId = data["userId"] as? String,
              let imageURL = data["imageURL"] as? String else {
            return nil
        }
        
        let caption = data["caption"] as? String
        let recipients = data["recipients"] as? [String] ?? []
        let viewedBy = data["viewedBy"] as? [String] ?? []
        let isStory = data["isStory"] as? Bool ?? false
        let viewDuration = data["viewDuration"] as? TimeInterval ?? 10.0
        let maxViews = data["maxViews"] as? Int ?? 1
        let viewCount = data["viewCount"] as? Int ?? 0
        let metadata = data["metadata"] as? [String: Any] ?? [:]
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let expiresAt: Date?
        if let timestamp = data["expiresAt"] as? Timestamp {
            expiresAt = timestamp.dateValue()
        } else {
            expiresAt = nil
        }
        
        return Photo(
            id: id,
            userId: userId,
            imageURL: imageURL,
            caption: caption,
            recipients: recipients,
            createdAt: createdAt,
            expiresAt: expiresAt,
            viewedBy: viewedBy,
            isStory: isStory,
            viewDuration: viewDuration,
            maxViews: maxViews,
            viewCount: viewCount,
            metadata: metadata
        )
    }
    
    // MARK: - Utility Methods
    
    /// Get a formatted timestamp string
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        let now = Date()
        
        if Calendar.current.isDateInToday(createdAt) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: createdAt)
    }
    
    /// Get remaining time until expiration
    /// - Returns: Remaining time in seconds, or nil if no expiration
    var remainingTime: TimeInterval? {
        guard let expiresAt = expiresAt else {
            // For stories, calculate remaining time in 24-hour window
            if isStory {
                let twentyFourHours: TimeInterval = 24 * 60 * 60
                let elapsed = Date().timeIntervalSince(createdAt)
                let remaining = twentyFourHours - elapsed
                return max(0, remaining)
            }
            return nil
        }
        
        let remaining = expiresAt.timeIntervalSince(Date())
        return max(0, remaining)
    }
    
    /// Get formatted remaining time string
    var formattedRemainingTime: String? {
        guard let remaining = remainingTime else { return nil }
        
        if remaining < 60 {
            return "\(Int(remaining))s"
        } else if remaining < 3600 {
            let minutes = Int(remaining / 60)
            return "\(minutes)m"
        } else {
            let hours = Int(remaining / 3600)
            return "\(hours)h"
        }
    }
    
    /// Check if this photo belongs to the current user
    /// - Parameter currentUserId: ID of the current user
    /// - Returns: True if the photo belongs to the current user
    func belongsToCurrentUser(_ currentUserId: String) -> Bool {
        return userId == currentUserId
    }
    
    // MARK: - Equatable & Hashable
    
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.id == rhs.id
    }
    
    override var hash: Int {
        return id.hashValue
    }
}

// MARK: - Photo Extensions

extension Photo {
    /// Convenience initializer for story photos
    /// - Parameters:
    ///   - userId: ID of the user creating the story
    ///   - imageURL: URL of the story image
    ///   - caption: Optional caption
    convenience init(storyPhoto userId: String,
                    imageURL: String,
                    caption: String? = nil) {
        self.init(
            userId: userId,
            imageURL: imageURL,
            caption: caption,
            recipients: [], // Stories don't have specific recipients
            isStory: true,
            viewDuration: 0, // Stories don't auto-expire after viewing
            maxViews: Int.max // Stories can be viewed multiple times
        )
    }
    
    /// Convenience initializer for ephemeral snaps
    /// - Parameters:
    ///   - userId: ID of the user creating the snap
    ///   - imageURL: URL of the snap image
    ///   - recipients: Array of recipient user IDs
    ///   - caption: Optional caption
    ///   - viewDuration: Duration the snap is visible
    convenience init(ephemeralSnap userId: String,
                    imageURL: String,
                    recipients: [String],
                    caption: String? = nil,
                    viewDuration: TimeInterval = 10.0) {
        self.init(
            userId: userId,
            imageURL: imageURL,
            caption: caption,
            recipients: recipients,
            isStory: false,
            viewDuration: viewDuration,
            maxViews: 1 // Ephemeral snaps can only be viewed once
        )
    }
}