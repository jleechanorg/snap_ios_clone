//
//  Story.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Story model for ephemeral content
//  Requirements: Firebase integration, 24-hour expiration
//

import Foundation

struct Story: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let mediaURL: String
    let thumbnailURL: URL?
    let caption: String?
    let createdAt: Date
    let expiresAt: Date
    let viewCount: Int
    let isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        username: String,
        mediaURL: String,
        thumbnailURL: URL? = nil,
        caption: String? = nil,
        createdAt: Date = Date(),
        viewCount: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.username = username
        self.mediaURL = mediaURL
        self.thumbnailURL = thumbnailURL
        self.caption = caption
        self.createdAt = createdAt
        self.expiresAt = createdAt.addingTimeInterval(24 * 60 * 60) // 24 hours
        self.viewCount = viewCount
        self.isActive = Date() < expiresAt
    }
    
    var timeAgo: String {
        let timeInterval = Date().timeIntervalSince(createdAt)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            return "1d ago"
        }
    }
    
    var timeUntilExpiration: TimeInterval {
        return expiresAt.timeIntervalSince(Date())
    }
    
    var hasExpired: Bool {
        return Date() > expiresAt
    }
}

extension Story {
    static var mockStories: [Story] = [
        Story(
            userId: "user1",
            username: "john_doe",
            mediaURL: "https://example.com/story1.jpg",
            caption: "Having a great day!"
        ),
        Story(
            userId: "user2", 
            username: "jane_smith",
            mediaURL: "https://example.com/story2.jpg",
            caption: "Beach vibes 🏖️"
        ),
        Story(
            userId: "user3",
            username: "mike_j",
            mediaURL: "https://example.com/story3.jpg",
            caption: nil
        ),
        Story(
            userId: "user4",
            username: "sarah_w",
            mediaURL: "https://example.com/story4.jpg",
            caption: "Weekend adventures"
        ),
        Story(
            userId: "user5",
            username: "alex_brown",
            mediaURL: "https://example.com/story5.jpg",
            caption: "Coffee time ☕"
        )
    ]
}