//
//  Conversation.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Conversation model for messaging functionality
//  Requirements: Firebase integration, ephemeral messaging
//

import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable {
    let id: String
    let participants: [String]
    let otherUserId: String
    let otherUserName: String
    let lastMessage: String
    let lastMessageTime: String
    let lastMessageTimestamp: Date
    let unreadCount: Int
    let isOnline: Bool
    let lastActiveTime: String
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        participants: [String],
        otherUserId: String,
        otherUserName: String,
        lastMessage: String = "",
        lastMessageTimestamp: Date = Date(),
        unreadCount: Int = 0,
        isOnline: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.participants = participants
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCount = unreadCount
        self.isOnline = isOnline
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Format time display
        let timeInterval = Date().timeIntervalSince(lastMessageTimestamp)
        if timeInterval < 60 {
            self.lastMessageTime = "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            self.lastMessageTime = "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            self.lastMessageTime = "\(hours)h"
        } else {
            let days = Int(timeInterval / 86400)
            self.lastMessageTime = "\(days)d"
        }
        
        // Format last active time
        if isOnline {
            self.lastActiveTime = "Active now"
        } else {
            let activeInterval = Date().timeIntervalSince(updatedAt)
            if activeInterval < 60 {
                self.lastActiveTime = "1m ago"
            } else if activeInterval < 3600 {
                let minutes = Int(activeInterval / 60)
                self.lastActiveTime = "\(minutes)m ago"
            } else if activeInterval < 86400 {
                let hours = Int(activeInterval / 3600)
                self.lastActiveTime = "\(hours)h ago"
            } else {
                let days = Int(activeInterval / 86400)
                self.lastActiveTime = "\(days)d ago"
            }
        }
    }
    
    static func generateId(for participants: [String]) -> String {
        return participants.sorted().joined(separator: "_")
    }
    
    static func createNew(with userId: String) -> Conversation {
        return Conversation(
            participants: ["current_user", userId],
            otherUserId: userId,
            otherUserName: "Friend",
            lastMessage: "Start a conversation",
            isOnline: true
        )
    }
}

// MARK: - Mock Data
extension Conversation {
    static var mockConversations: [Conversation] {
        let baseDate = Date()
        
        return [
            Conversation(
                participants: ["current_user", "friend1"],
                otherUserId: "friend1",
                otherUserName: "John Doe",
                lastMessage: "Hey! What's up? 👋",
                lastMessageTimestamp: baseDate.addingTimeInterval(-300), // 5 minutes ago
                unreadCount: 2,
                isOnline: true
            ),
            Conversation(
                participants: ["current_user", "friend2"],
                otherUserId: "friend2",
                otherUserName: "Jane Smith",
                lastMessage: "Check out this photo!",
                lastMessageTimestamp: baseDate.addingTimeInterval(-1800), // 30 minutes ago
                unreadCount: 0,
                isOnline: false
            ),
            Conversation(
                participants: ["current_user", "friend3"],
                otherUserId: "friend3",
                otherUserName: "Mike Johnson",
                lastMessage: "😂😂😂",
                lastMessageTimestamp: baseDate.addingTimeInterval(-3600), // 1 hour ago
                unreadCount: 1,
                isOnline: true
            ),
            Conversation(
                participants: ["current_user", "friend4"],
                otherUserId: "friend4",
                otherUserName: "Sarah Wilson",
                lastMessage: "See you tomorrow!",
                lastMessageTimestamp: baseDate.addingTimeInterval(-7200), // 2 hours ago
                unreadCount: 0,
                isOnline: false
            ),
            Conversation(
                participants: ["current_user", "friend5"],
                otherUserId: "friend5",
                otherUserName: "Alex Brown",
                lastMessage: "That was amazing! 🎉",
                lastMessageTimestamp: baseDate.addingTimeInterval(-21600), // 6 hours ago
                unreadCount: 3,
                isOnline: true
            )
        ]
    }
}