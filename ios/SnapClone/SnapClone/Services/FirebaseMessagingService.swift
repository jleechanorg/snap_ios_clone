//
//  FirebaseMessagingService.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Real-time messaging service with ephemeral message cleanup
//  Requirements: iOS 16+, Firebase Firestore SDK
//

import Foundation
import FirebaseFirestore
import Combine

/// Custom messaging errors
enum MessagingError: LocalizedError {
    case invalidMessage
    case userNotAuthenticated
    case recipientNotFound
    case messageNotFound
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidMessage:
            return "Invalid message content."
        case .userNotAuthenticated:
            return "User must be authenticated to send messages."
        case .recipientNotFound:
            return "Recipient not found."
        case .messageNotFound:
            return "Message not found."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .unknown(let message):
            return message
        }
    }
}

/// Firebase messaging service for real-time ephemeral messaging
@MainActor
final class FirebaseMessagingService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently loaded messages
    @Published var messages: [Message] = []
    
    /// Loading state for messaging operations
    @Published var isLoading = false
    
    /// Current messaging error
    @Published var messagingError: MessagingError?
    
    // MARK: - Private Properties
    
    private let firestore = Firestore.firestore()
    private let authService = FirebaseAuthService.shared
    private var messageListeners: [String: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var cleanupTimer: Timer?
    
    // MARK: - Singleton
    
    static let shared = FirebaseMessagingService()
    
    // MARK: - Initialization
    
    private init() {
        setupCleanupTimer()
    }
    
    deinit {
        removeAllListeners()
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Message Operations
    
    /// Send a message to a recipient
    /// - Parameter message: Message to send
    /// - Throws: MessagingError for sending failures
    func sendMessage(_ message: Message) async throws {
        guard authService.isAuthenticated else {
            throw MessagingError.userNotAuthenticated
        }
        
        guard !message.content.isEmpty else {
            throw MessagingError.invalidMessage
        }
        
        isLoading = true
        messagingError = nil
        
        defer { isLoading = false }
        
        do {
            let messageData = message.toDictionary()
            
            // Add message to Firestore
            try await firestore.collection("messages").document(message.id).setData(messageData)
            
            // Update message status to delivered
            message.markAsDelivered()
            try await updateMessageStatus(message)
            
            print("Message sent: \(message.id)")
        } catch {
            let messagingError = MessagingError.unknown(error.localizedDescription)
            self.messagingError = messagingError
            throw messagingError
        }
    }
    
    /// Get messages between two users
    /// - Parameters:
    ///   - userId1: First user ID
    ///   - userId2: Second user ID
    /// - Returns: Array of messages between the users
    func getMessages(between userId1: String, between userId2: String) async throws -> [Message] {
        guard authService.isAuthenticated else {
            throw MessagingError.userNotAuthenticated
        }
        
        isLoading = true
        messagingError = nil
        
        defer { isLoading = false }
        
        do {
            let query = firestore.collection("messages")
                .whereFilter(Filter.orFilter([
                    Filter.andFilter([
                        Filter.whereField("senderId", isEqualTo: userId1),
                        Filter.whereField("receiverId", isEqualTo: userId2)
                    ]),
                    Filter.andFilter([
                        Filter.whereField("senderId", isEqualTo: userId2),
                        Filter.whereField("receiverId", isEqualTo: userId1)
                    ])
                ]))
                .order(by: "timestamp", descending: false)
            
            let snapshot = try await query.getDocuments()
            
            let messages = snapshot.documents.compactMap { document in
                Message.from(document: document)
            }
            
            return messages
        } catch {
            let messagingError = MessagingError.unknown(error.localizedDescription)
            self.messagingError = messagingError
            throw messagingError
        }
    }
    
    /// Mark a message as read
    /// - Parameter message: Message to mark as read
    /// - Throws: MessagingError for update failures
    func markAsRead(_ message: Message) async throws {
        guard authService.isAuthenticated else {
            throw MessagingError.userNotAuthenticated
        }
        
        // Only the recipient can mark a message as read
        guard message.receiverId == authService.currentUserId else {
            return
        }
        
        do {
            message.markAsViewed()
            try await updateMessage(message)
            
            print("Message marked as read: \(message.id)")
        } catch {
            let messagingError = MessagingError.unknown(error.localizedDescription)
            self.messagingError = messagingError
            throw messagingError
        }
    }
    
    /// Delete a message
    /// - Parameter message: Message to delete
    /// - Throws: MessagingError for deletion failures
    func deleteMessage(_ message: Message) async throws {
        guard authService.isAuthenticated else {
            throw MessagingError.userNotAuthenticated
        }
        
        // Only the sender can delete a message
        guard message.senderId == authService.currentUserId else {
            throw MessagingError.unknown("Only the sender can delete this message")
        }
        
        do {
            try await firestore.collection("messages").document(message.id).delete()
            
            // Remove from local messages array
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages.remove(at: index)
            }
            
            print("Message deleted: \(message.id)")
        } catch {
            let messagingError = MessagingError.unknown(error.localizedDescription)
            self.messagingError = messagingError
            throw messagingError
        }
    }
    
    /// Update message data in Firestore
    /// - Parameter message: Message to update
    /// - Throws: Error if update fails
    private func updateMessage(_ message: Message) async throws {
        try await firestore.collection("messages").document(message.id).updateData(message.toDictionary())
    }
    
    /// Update message status in Firestore
    /// - Parameter message: Message to update
    /// - Throws: Error if update fails
    private func updateMessageStatus(_ message: Message) async throws {
        try await firestore.collection("messages").document(message.id).updateData([
            "status": message.status.rawValue,
            "viewedAt": message.viewedAt != nil ? Timestamp(date: message.viewedAt!) : NSNull()
        ])
    }
    
    // MARK: - Real-time Listeners
    
    /// Start listening for messages between two users
    /// - Parameters:
    ///   - userId1: First user ID
    ///   - userId2: Second user ID
    /// - Returns: AsyncStream of message updates
    func listenForMessages(between userId1: String, and userId2: String) -> AsyncStream<[Message]> {
        let conversationId = getConversationId(userId1: userId1, userId2: userId2)
        
        return AsyncStream { continuation in
            let query = firestore.collection("messages")
                .whereFilter(Filter.orFilter([
                    Filter.andFilter([
                        Filter.whereField("senderId", isEqualTo: userId1),
                        Filter.whereField("receiverId", isEqualTo: userId2)
                    ]),
                    Filter.andFilter([
                        Filter.whereField("senderId", isEqualTo: userId2),
                        Filter.whereField("receiverId", isEqualTo: userId1)
                    ])
                ]))
                .order(by: "timestamp", descending: false)
            
            let listener = query.addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening for messages: \(error)")
                    continuation.finish()
                    return
                }
                
                guard let snapshot = snapshot else {
                    continuation.finish()
                    return
                }
                
                let messages = snapshot.documents.compactMap { document in
                    Message.from(document: document)
                }
                
                Task { @MainActor in
                    self?.messages = messages
                }
                
                continuation.yield(messages)
            }
            
            messageListeners[conversationId] = listener
            
            continuation.onTermination = { _ in
                listener.remove()
                self.messageListeners.removeValue(forKey: conversationId)
            }
        }
    }
    
    /// Get conversation ID for two users
    /// - Parameters:
    ///   - userId1: First user ID
    ///   - userId2: Second user ID
    /// - Returns: Consistent conversation ID
    private func getConversationId(userId1: String, userId2: String) -> String {
        return [userId1, userId2].sorted().joined(separator: "_")
    }
    
    /// Remove listener for a conversation
    /// - Parameters:
    ///   - userId1: First user ID
    ///   - userId2: Second user ID
    func removeMessageListener(between userId1: String, and userId2: String) {
        let conversationId = getConversationId(userId1: userId1, userId2: userId2)
        messageListeners[conversationId]?.remove()
        messageListeners.removeValue(forKey: conversationId)
    }
    
    /// Remove all message listeners
    private func removeAllListeners() {
        messageListeners.values.forEach { $0.remove() }
        messageListeners.removeAll()
    }
    
    // MARK: - Ephemeral Message Cleanup
    
    /// Setup timer for ephemeral message cleanup
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.cleanupExpiredMessages()
            }
        }
    }
    
    /// Clean up expired ephemeral messages
    private func cleanupExpiredMessages() async {
        do {
            let now = Timestamp(date: Date())
            
            // Query for expired messages
            let expiredQuery = firestore.collection("messages")
                .whereField("isEphemeral", isEqualTo: true)
                .whereField("expiresAt", isLessThan: now)
            
            let snapshot = try await expiredQuery.getDocuments()
            
            // Delete expired messages in batch
            let batch = firestore.batch()
            
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            
            try await batch.commit()
            
            if !snapshot.documents.isEmpty {
                print("Cleaned up \(snapshot.documents.count) expired messages")
            }
        } catch {
            print("Error cleaning up expired messages: \(error)")
        }
    }
    
    /// Force cleanup of messages that should auto-delete
    func forceCleanupMessages() async {
        await cleanupExpiredMessages()
    }
    
    // MARK: - Utility Methods
    
    /// Get recent conversations for a user
    /// - Parameter userId: User ID to get conversations for
    /// - Returns: Array of recent messages representing conversations
    func getRecentConversations(for userId: String) async throws -> [Message] {
        guard authService.isAuthenticated else {
            throw MessagingError.userNotAuthenticated
        }
        
        do {
            let sentQuery = firestore.collection("messages")
                .whereField("senderId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
            
            let receivedQuery = firestore.collection("messages")
                .whereField("receiverId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
            
            let [sentSnapshot, receivedSnapshot] = try await [
                sentQuery.getDocuments(),
                receivedQuery.getDocuments()
            ]
            
            var allMessages: [Message] = []
            
            allMessages.append(contentsOf: sentSnapshot.documents.compactMap { Message.from(document: $0) })
            allMessages.append(contentsOf: receivedSnapshot.documents.compactMap { Message.from(document: $0) })
            
            // Sort by timestamp and group by conversation
            allMessages.sort { $0.timestamp > $1.timestamp }
            
            var conversations: [String: Message] = [:]
            
            for message in allMessages {
                let conversationId = getConversationId(userId1: message.senderId, userId2: message.receiverId)
                if conversations[conversationId] == nil {
                    conversations[conversationId] = message
                }
            }
            
            return Array(conversations.values).sorted { $0.timestamp > $1.timestamp }
        } catch {
            let messagingError = MessagingError.unknown(error.localizedDescription)
            self.messagingError = messagingError
            throw messagingError
        }
    }
    
    /// Clear messaging error
    func clearError() {
        messagingError = nil
    }
    
    /// Get unread message count for a user
    /// - Parameter userId: User ID to check
    /// - Returns: Number of unread messages
    func getUnreadMessageCount(for userId: String) async throws -> Int {
        guard authService.isAuthenticated else {
            throw MessagingError.userNotAuthenticated
        }
        
        do {
            let query = firestore.collection("messages")
                .whereField("receiverId", isEqualTo: userId)
                .whereField("viewedAt", isEqualTo: NSNull())
            
            let snapshot = try await query.getDocuments()
            return snapshot.documents.count
        } catch {
            throw MessagingError.unknown(error.localizedDescription)
        }
    }
}

// MARK: - FirebaseMessagingService Extensions

extension FirebaseMessagingService {
    /// Create a text message
    /// - Parameters:
    ///   - text: Message text
    ///   - recipientId: Recipient user ID
    ///   - isEphemeral: Whether message is ephemeral
    ///   - viewDuration: View duration for ephemeral messages
    /// - Returns: Created message
    func createTextMessage(
        text: String,
        recipientId: String,
        isEphemeral: Bool = true,
        viewDuration: TimeInterval = 10.0
    ) -> Message? {
        guard let currentUserId = authService.currentUserId else { return nil }
        
        return Message(
            textMessage: currentUserId,
            receiverId: recipientId,
            text: text,
            isEphemeral: isEphemeral,
            viewDuration: viewDuration
        )
    }
    
    /// Create a media message
    /// - Parameters:
    ///   - mediaURL: Media URL
    ///   - type: Media type
    ///   - recipientId: Recipient user ID
    ///   - isEphemeral: Whether message is ephemeral
    ///   - viewDuration: View duration for ephemeral messages
    /// - Returns: Created message
    func createMediaMessage(
        mediaURL: String,
        type: MessageType,
        recipientId: String,
        isEphemeral: Bool = true,
        viewDuration: TimeInterval = 10.0
    ) -> Message? {
        guard let currentUserId = authService.currentUserId else { return nil }
        
        return Message(
            mediaMessage: currentUserId,
            receiverId: recipientId,
            mediaURL: mediaURL,
            type: type,
            isEphemeral: isEphemeral,
            viewDuration: viewDuration
        )
    }
}