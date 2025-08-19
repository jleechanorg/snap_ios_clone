import Foundation
import Firebase
import FirebaseFirestore
import Combine

protocol MessagingServiceProtocol {
    func sendMessage(_ message: Message) async throws
    func getConversation(with userId: String) async throws -> Conversation
    func getMessages(for conversationId: String, limit: Int) async throws -> [Message]
    func listenToMessages(for conversationId: String) -> AnyPublisher<[Message], Error>
    func markMessageAsViewed(_ messageId: String) async throws
    func deleteExpiredMessages() async throws
    func reportScreenshot(for messageId: String) async throws
}

class FirebaseMessagingService: MessagingServiceProtocol {
    static let shared = FirebaseMessagingService()
    
    private let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    private var listeners: [String: ListenerRegistration] = [:]
    
    private init() {
        setupEphemeralMessageCleanup()
    }
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - Message Management
    
    func sendMessage(_ message: Message) async throws {
        var messageToSend = message
        
        // Ensure conversation exists
        let conversation = try await getOrCreateConversation(participantIds: [message.senderId, message.receiverId])
        messageToSend.conversationId = conversation.id ?? Conversation.generateId(for: [message.senderId, message.receiverId])
        
        // Upload media if present
        if let mediaURL = message.mediaURL, mediaURL.hasPrefix("file://") {
            let uploadedURL = try await uploadMedia(localURL: URL(string: mediaURL)!)
            messageToSend.mediaURL = uploadedURL
        }
        
        // Save message to Firestore
        let messageRef = firestore.collection("messages").document()
        messageToSend.id = messageRef.documentID
        
        try await messageRef.setData(from: messageToSend)
        
        // Update conversation
        try await updateConversationLastMessage(conversationId: messageToSend.conversationId, message: messageToSend)
        
        // Send push notification
        await sendPushNotification(for: messageToSend)
    }
    
    func getConversation(with userId: String) async throws -> Conversation {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw MessagingError.userNotAuthenticated
        }
        
        return try await getOrCreateConversation(participantIds: [currentUserId, userId])
    }
    
    func getMessages(for conversationId: String, limit: Int = 50) async throws -> [Message] {
        let query = firestore.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        let messages = try snapshot.documents.compactMap { document in
            try document.data(as: Message.self)
        }
        
        // Filter out expired ephemeral messages
        return messages.filter { !$0.isExpired }
    }
    
    func listenToMessages(for conversationId: String) -> AnyPublisher<[Message], Error> {
        let subject = PassthroughSubject<[Message], Error>()
        
        let query = firestore.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "timestamp", descending: false)
        
        let listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            do {
                let messages = try snapshot.documents.compactMap { document in
                    try document.data(as: Message.self)
                }.filter { !$0.isExpired } // Filter expired messages
                
                subject.send(messages)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        
        // Store listener for cleanup
        listeners[conversationId] = listener
        
        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
                self.listeners.removeValue(forKey: conversationId)
            })
            .eraseToAnyPublisher()
    }
    
    func markMessageAsViewed(_ messageId: String) async throws {
        let messageRef = firestore.collection("messages").document(messageId)
        
        let updateData: [String: Any] = [
            "status": MessageStatus.viewed.rawValue,
            "viewedAt": Timestamp(date: Date())
        ]
        
        try await messageRef.updateData(updateData)
        
        // Set expiration for ephemeral messages
        let document = try await messageRef.getDocument()
        if var message = try? document.data(as: Message.self),
           message.isEphemeral && message.viewedAt == nil {
            
            message.markAsViewed()
            
            let expirationData: [String: Any] = [
                "expiresAt": Timestamp(date: message.expiresAt!)
            ]
            
            try await messageRef.updateData(expirationData)
            
            // Schedule deletion
            scheduleMessageDeletion(messageId: messageId, expiresAt: message.expiresAt!)
        }
    }
    
    func reportScreenshot(for messageId: String) async throws {
        let messageRef = firestore.collection("messages").document(messageId)
        
        try await messageRef.updateData([
            "screenshotTaken": true
        ])
        
        // Notify sender about screenshot
        let document = try await messageRef.getDocument()
        if let message = try? document.data(as: Message.self) {
            await notifyScreenshotTaken(for: message)
        }
    }
    
    // MARK: - Conversation Management
    
    private func getOrCreateConversation(participantIds: [String]) async throws -> Conversation {
        let conversationId = Conversation.generateId(for: participantIds)
        let conversationRef = firestore.collection("conversations").document(conversationId)
        
        let document = try await conversationRef.getDocument()
        
        if document.exists {
            return try document.data(as: Conversation.self)
        } else {
            // Create new conversation
            let conversation = Conversation(participants: participantIds)
            try await conversationRef.setData(from: conversation)
            return conversation
        }
    }
    
    private func updateConversationLastMessage(conversationId: String, message: Message) async throws {
        let conversationRef = firestore.collection("conversations").document(conversationId)
        
        let updateData: [String: Any] = [
            "lastMessageTimestamp": Timestamp(date: message.timestamp),
            "lastMessage": try Firestore.Encoder().encode(message)
        ]
        
        try await conversationRef.updateData(updateData)
        
        // Update unread count for receiver
        try await incrementUnreadCount(conversationId: conversationId, userId: message.receiverId)
    }
    
    private func incrementUnreadCount(conversationId: String, userId: String) async throws {
        let conversationRef = firestore.collection("conversations").document(conversationId)
        
        try await conversationRef.updateData([
            "unreadCount.\(userId)": FieldValue.increment(Int64(1))
        ])
    }
    
    // MARK: - Media Upload
    
    private func uploadMedia(localURL: URL) async throws -> String {
        let fileName = UUID().uuidString + "_" + localURL.lastPathComponent
        let storageRef = storage.reference().child("messages/\(fileName)")
        
        let data = try Data(contentsOf: localURL)
        
        _ = try await storageRef.putDataAsync(data)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Ephemeral Message Management
    
    func deleteExpiredMessages() async throws {
        let expiredQuery = firestore.collection("messages")
            .whereField("isEphemeral", isEqualTo: true)
            .whereField("expiresAt", isLessThan: Timestamp(date: Date()))
        
        let snapshot = try await expiredQuery.getDocuments()
        
        let batch = firestore.batch()
        
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
    }
    
    private func scheduleMessageDeletion(messageId: String, expiresAt: Date) {
        let timeInterval = expiresAt.timeIntervalSinceNow
        
        if timeInterval > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
                Task {
                    try? await self?.deleteMessage(messageId: messageId)
                }
            }
        }
    }
    
    private func deleteMessage(messageId: String) async throws {
        let messageRef = firestore.collection("messages").document(messageId)
        
        // Get message data before deletion to clean up media
        let document = try await messageRef.getDocument()
        if let message = try? document.data(as: Message.self),
           let mediaURL = message.mediaURL {
            try? await deleteMediaFile(url: mediaURL)
        }
        
        try await messageRef.delete()
    }
    
    private func deleteMediaFile(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
    }
    
    private func setupEphemeralMessageCleanup() {
        // Run cleanup every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task {
                try? await self?.deleteExpiredMessages()
            }
        }
    }
    
    // MARK: - Push Notifications
    
    private func sendPushNotification(for message: Message) async {
        // Get receiver's device token
        guard let receiverToken = try? await getUserDeviceToken(userId: message.receiverId),
              let senderUser = try? await getUserProfile(userId: message.senderId) else {
            return
        }
        
        let notificationData: [String: Any] = [
            "to": receiverToken,
            "notification": [
                "title": senderUser.displayName,
                "body": message.messageType == .text ? (message.content ?? "Sent a message") : "Sent a photo",
                "sound": "default"
            ],
            "data": [
                "messageId": message.id ?? "",
                "conversationId": message.conversationId,
                "senderId": message.senderId,
                "type": "message"
            ]
        ]
        
        // Send via FCM (this would be implemented with your backend service)
        // For now, we'll skip the actual HTTP request
    }
    
    private func notifyScreenshotTaken(for message: Message) async {
        // Send notification to sender about screenshot
        guard let senderToken = try? await getUserDeviceToken(userId: message.senderId) else {
            return
        }
        
        let notificationData: [String: Any] = [
            "to": senderToken,
            "notification": [
                "title": "Screenshot Alert",
                "body": "Someone took a screenshot of your snap",
                "sound": "default"
            ],
            "data": [
                "messageId": message.id ?? "",
                "type": "screenshot"
            ]
        ]
        
        // Send via FCM
    }
    
    // MARK: - Helper Methods
    
    private func getUserDeviceToken(userId: String) async throws -> String? {
        let document = try await firestore.collection("users").document(userId).getDocument()
        return document.data()?["deviceToken"] as? String
    }
    
    private func getUserProfile(userId: String) async throws -> User {
        let document = try await firestore.collection("users").document(userId).getDocument()
        return try document.data(as: User.self)
    }
    
    private func removeAllListeners() {
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
}

// MARK: - Messaging Errors

enum MessagingError: LocalizedError {
    case userNotAuthenticated
    case conversationNotFound
    case messageNotFound
    case uploadFailed
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .conversationNotFound:
            return "Conversation not found"
        case .messageNotFound:
            return "Message not found"
        case .uploadFailed:
            return "Media upload failed"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}