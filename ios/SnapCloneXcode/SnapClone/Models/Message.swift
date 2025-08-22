//
//  Message.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Ephemeral message model with auto-delete functionality
//  Requirements: iOS 16+, Firebase SDK
//

import Foundation
import FirebaseFirestore

/// Enumeration for different message types
enum MessageType: String, CaseIterable, Codable {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        }
    }
}

/// Enumeration for message status tracking
enum MessageStatus: String, CaseIterable, Codable {
    case sent = "sent"
    case delivered = "delivered"
    case viewed = "viewed"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .viewed: return "Viewed"
        case .expired: return "Expired"
        }
    }
}

/// Represents an ephemeral message in the SnapClone application
/// Supports automatic deletion and view tracking
@objc(Message)
final class Message: NSObject, Codable, Identifiable, ObservableObject {
    
    // MARK: - Properties
    
    /// Unique identifier for the message
    let id: String
    
    /// ID of the user who sent the message
    let senderId: String
    
    /// ID of the user who receives the message
    let receiverId: String
    
    /// Conversation ID for grouping messages
    let conversationId: String
    
    /// Message content (text or media URL)
    @Published var content: String?
    
    /// Media URL for image/video messages
    let mediaURL: String?
    
    /// Whether the message has been read
    @Published var isRead: Bool
    
    /// Type of message (text, image, video, audio)
    let type: MessageType
    
    /// Timestamp when the message was created
    let timestamp: Date
    
    /// Optional expiration date for ephemeral messages
    @Published var expiresAt: Date?
    
    /// Timestamp when the message was viewed (nil if not viewed)
    @Published var viewedAt: Date?
    
    /// Whether this message is ephemeral (auto-deletes after viewing)
    let isEphemeral: Bool
    
    /// Duration the message is visible when viewed (for ephemeral messages)
    let viewDuration: TimeInterval
    
    /// Current status of the message
    @Published var status: MessageStatus
    
    /// Additional metadata for the message
    @Published var metadata: [String: Any]
    
    // MARK: - Coding Keys
    
    private enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case receiverId
        case conversationId
        case content
        case mediaURL
        case type
        case timestamp
        case expiresAt
        case viewedAt
        case isEphemeral
        case isRead
        case viewDuration
        case status
        case metadata
    }
    
    // MARK: - Initializers
    
    /// Initialize a new message
    /// - Parameters:
    ///   - id: Unique message identifier
    ///   - conversationId: ID of the conversation
    ///   - senderId: ID of the sender
    ///   - receiverId: ID of the receiver
    ///   - content: Message content
    ///   - mediaURL: Media URL for image/video messages
    ///   - messageType: Message type (renamed from type)
    ///   - timestamp: Creation timestamp
    ///   - expiresAt: Optional expiration date
    ///   - viewedAt: Optional view timestamp
    ///   - isEphemeral: Whether message is ephemeral
    ///   - isRead: Whether message has been read
    ///   - viewDuration: View duration for ephemeral messages
    ///   - status: Message status
    ///   - metadata: Additional metadata
    init(id: String = UUID().uuidString,
         conversationId: String,
         senderId: String,
         receiverId: String,
         content: String? = nil,
         mediaURL: String? = nil,
         messageType: MessageType,
         timestamp: Date = Date(),
         expiresAt: Date? = nil,
         viewedAt: Date? = nil,
         isEphemeral: Bool = true,
         isRead: Bool = false,
         viewDuration: TimeInterval = 10.0,
         status: MessageStatus = .sent,
         metadata: [String: Any] = [:]) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.mediaURL = mediaURL
        self.type = messageType
        self.isRead = isRead
        self.timestamp = timestamp
        self.expiresAt = expiresAt
        self.viewedAt = viewedAt
        self.isEphemeral = isEphemeral
        self.viewDuration = viewDuration
        self.status = status
        self.metadata = metadata
        super.init()
    }
    
    // MARK: - Codable Implementation
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        senderId = try container.decode(String.self, forKey: .senderId)
        receiverId = try container.decode(String.self, forKey: .receiverId)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        mediaURL = try container.decodeIfPresent(String.self, forKey: .mediaURL)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        type = try container.decode(MessageType.self, forKey: .type)
        
        // Handle date decoding from Firestore Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
        
        if let expiresAtTimestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .expiresAt) {
            expiresAt = expiresAtTimestamp.dateValue()
        } else {
            expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        }
        
        if let viewedAtTimestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .viewedAt) {
            viewedAt = viewedAtTimestamp.dateValue()
        } else {
            viewedAt = try container.decodeIfPresent(Date.self, forKey: .viewedAt)
        }
        
        isEphemeral = try container.decodeIfPresent(Bool.self, forKey: .isEphemeral) ?? true
        viewDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .viewDuration) ?? 10.0
        status = try container.decodeIfPresent(MessageStatus.self, forKey: .status) ?? .sent
        metadata = [:]  // TODO: Implement proper metadata decoding
        
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(viewedAt, forKey: .viewedAt)
        try container.encode(isEphemeral, forKey: .isEphemeral)
        try container.encode(viewDuration, forKey: .viewDuration)
        try container.encode(status, forKey: .status)
        // Note: metadata encoding may need custom handling for complex types
    }
    
    // MARK: - Message Logic
    
    /// Check if the message has expired
    /// - Returns: True if the message has expired
    var hasExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    /// Check if the message can still be viewed
    /// - Returns: True if the message can be viewed
    var canBeViewed: Bool {
        return !hasExpired && viewedAt == nil
    }
    
    /// Mark the message as viewed
    /// - Parameter viewedAt: Optional timestamp for when viewed (defaults to now)
    func markAsViewed(at viewedAt: Date = Date()) {
        guard canBeViewed else { return }
        
        self.viewedAt = viewedAt
        self.status = .viewed
        
        // Set expiration for ephemeral messages
        if isEphemeral {
            self.expiresAt = viewedAt.addingTimeInterval(viewDuration)
        }
    }
    
    /// Check if the message should be auto-deleted
    /// - Returns: True if the message should be deleted
    var shouldAutoDelete: Bool {
        // Auto-delete if expired and viewed
        if hasExpired && viewedAt != nil {
            return true
        }
        
        // Auto-delete ephemeral messages after view duration
        if isEphemeral, let viewedAt = viewedAt {
            let timeSinceViewed = Date().timeIntervalSince(viewedAt)
            return timeSinceViewed >= viewDuration
        }
        
        return false
    }
    
    /// Get the remaining view time for ephemeral messages
    /// - Returns: Remaining time in seconds, or nil if not applicable
    var remainingViewTime: TimeInterval? {
        guard isEphemeral, let viewedAt = viewedAt else { return nil }
        
        let elapsed = Date().timeIntervalSince(viewedAt)
        let remaining = viewDuration - elapsed
        
        return max(0, remaining)
    }
    
    /// Mark the message as delivered
    func markAsDelivered() {
        guard status == .sent else { return }
        status = .delivered
    }
    
    /// Mark the message as expired
    func markAsExpired() {
        status = .expired
    }
    
    // MARK: - Firebase Integration
    
    /// Convert message to dictionary for Firebase storage
    /// - Returns: Dictionary representation for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "senderId": senderId,
            "receiverId": receiverId,
            "content": content,
            "type": type.rawValue,
            "timestamp": Timestamp(date: timestamp),
            "isEphemeral": isEphemeral,
            "viewDuration": viewDuration,
            "status": status.rawValue
        ]
        
        if let expiresAt = expiresAt {
            dict["expiresAt"] = Timestamp(date: expiresAt)
        }
        
        if let viewedAt = viewedAt {
            dict["viewedAt"] = Timestamp(date: viewedAt)
        }
        
        if !metadata.isEmpty {
            dict["metadata"] = metadata
        }
        
        return dict
    }
    
    /// Create message from Firestore document snapshot
    /// - Parameter document: Firestore document snapshot
    /// - Returns: Message instance or nil if parsing fails
    static func from(document: DocumentSnapshot) -> Message? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        guard let senderId = data["senderId"] as? String,
              let receiverId = data["receiverId"] as? String else {
            return nil
        }
        
        let conversationId = data["conversationId"] as? String ?? ""
        let content = data["content"] as? String
        let mediaURL = data["mediaURL"] as? String
        
        guard let typeString = data["type"] as? String,
              let type = MessageType(rawValue: typeString) else {
            return nil
        }
        
        let timestamp: Date
        if let firestoreTimestamp = data["timestamp"] as? Timestamp {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            timestamp = Date()
        }
        
        let expiresAt: Date?
        if let firestoreTimestamp = data["expiresAt"] as? Timestamp {
            expiresAt = firestoreTimestamp.dateValue()
        } else {
            expiresAt = nil
        }
        
        let viewedAt: Date?
        if let firestoreTimestamp = data["viewedAt"] as? Timestamp {
            viewedAt = firestoreTimestamp.dateValue()
        } else {
            viewedAt = nil
        }
        
        let isEphemeral = data["isEphemeral"] as? Bool ?? true
        let viewDuration = data["viewDuration"] as? TimeInterval ?? 10.0
        
        let status: MessageStatus
        if let statusString = data["status"] as? String,
           let messageStatus = MessageStatus(rawValue: statusString) {
            status = messageStatus
        } else {
            status = .sent
        }
        
        let metadata = data["metadata"] as? [String: Any] ?? [:]
        
        return Message(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            mediaURL: mediaURL,
            messageType: type,
            timestamp: timestamp,
            expiresAt: expiresAt,
            viewedAt: viewedAt,
            isEphemeral: isEphemeral,
            viewDuration: viewDuration,
            status: status,
            metadata: metadata
        )
    }
    
    // MARK: - Utility Methods
    
    /// Get a formatted timestamp string
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        let now = Date()
        
        if Calendar.current.isDateInToday(timestamp) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: timestamp)
    }
    
    /// Check if this message is from the current user
    /// - Parameter currentUserId: ID of the current user
    /// - Returns: True if the message is from the current user
    func isFromCurrentUser(_ currentUserId: String) -> Bool {
        return senderId == currentUserId
    }
    
    // MARK: - Equatable & Hashable
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    override var hash: Int {
        return id.hashValue
    }
}

// MARK: - Message Extensions

extension Message {
    /// Convenience initializer for text messages
    /// - Parameters:
    ///   - senderId: ID of the sender
    ///   - receiverId: ID of the receiver
    ///   - text: Text content
    ///   - isEphemeral: Whether message is ephemeral
    ///   - viewDuration: View duration for ephemeral messages
    convenience init(textMessage senderId: String,
                    receiverId: String,
                    text: String,
                    isEphemeral: Bool = true,
                    viewDuration: TimeInterval = 10.0) {
        let conversationId = [senderId, receiverId].sorted().joined(separator: "_")
        self.init(
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            content: text,
            messageType: .text,
            isEphemeral: isEphemeral,
            viewDuration: viewDuration
        )
    }
    
    /// Convenience initializer for media messages
    /// - Parameters:
    ///   - senderId: ID of the sender
    ///   - receiverId: ID of the receiver
    ///   - mediaURL: URL of the media content
    ///   - type: Type of media (image, video, audio)
    ///   - isEphemeral: Whether message is ephemeral
    ///   - viewDuration: View duration for ephemeral messages
    convenience init(mediaMessage senderId: String,
                    receiverId: String,
                    mediaURL: String,
                    type: MessageType,
                    isEphemeral: Bool = true,
                    viewDuration: TimeInterval = 10.0) {
        let conversationId = [senderId, receiverId].sorted().joined(separator: "_")
        self.init(
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            mediaURL: mediaURL,
            messageType: type,
            isEphemeral: isEphemeral,
            viewDuration: viewDuration
        )
    }
}

// MARK: - Mock Data
extension Message {
    static func mockMessages(for conversationId: String) -> [Message] {
        let baseDate = Date()
        
        return [
            Message(
                conversationId: conversationId,
                senderId: "friend1",
                receiverId: "current_user",
                content: "Hey! What's up? 👋",
                messageType: .text,
                timestamp: baseDate.addingTimeInterval(-3600), // 1 hour ago
                isRead: true
            ),
            Message(
                conversationId: conversationId,
                senderId: "current_user",
                receiverId: "friend1",
                content: "Not much, just working on some code!",
                messageType: .text,
                timestamp: baseDate.addingTimeInterval(-3500), // 58 minutes ago
                isRead: true
            ),
            Message(
                conversationId: conversationId,
                senderId: "friend1",
                receiverId: "current_user",
                content: "Cool! I just took this amazing photo",
                mediaURL: "https://picsum.photos/300/400?random=1",
                messageType: .image,
                timestamp: baseDate.addingTimeInterval(-1800), // 30 minutes ago
                isRead: false
            ),
            Message(
                conversationId: conversationId,
                senderId: "current_user",
                receiverId: "friend1",
                content: "That looks awesome! 📸",
                messageType: .text,
                timestamp: baseDate.addingTimeInterval(-1200), // 20 minutes ago
                isRead: true
            ),
            Message(
                conversationId: conversationId,
                senderId: "friend1",
                receiverId: "current_user",
                content: "Want to grab coffee later?",
                messageType: .text,
                timestamp: baseDate.addingTimeInterval(-300), // 5 minutes ago
                isRead: false
            )
        ]
    }
}