//
//  ConversationView.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Individual conversation messaging interface
//  Requirements: iOS 16+, Firebase messaging integration
//

import SwiftUI

struct ConversationView: View {
    let conversation: Conversation
    let onBack: () -> Void
    
    @State private var messages: [Message] = []
    @State private var newMessageText = ""
    @State private var isLoading = false
    @EnvironmentObject var messagingService: FirebaseMessagingService
    @EnvironmentObject var authService: FirebaseAuthService
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(conversation.otherUserName.prefix(1).uppercased()))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading) {
                    Text(conversation.otherUserName)
                        .font(.headline)
                    
                    if conversation.isOnline {
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Last seen \\(conversation.lastActiveTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Video call action
                }) {
                    Image(systemName: "video.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 8) {
                    if isLoading {
                        ProgressView("Loading messages...")
                            .padding()
                    } else if messages.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "message")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No messages yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Send a snap to start the conversation!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        ForEach(messages) { message in
                            MessageBubbleView(
                                message: message,
                                isFromCurrentUser: message.senderId == authService.currentUserId
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // Message Input
            HStack {
                Button(action: {
                    // Camera action
                }) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                
                TextField("Type a message...", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(newMessageText.isEmpty ? .gray : .yellow)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        isLoading = true
        
        // Simulate loading messages
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.messages = Message.mockMessages(for: conversation.id)
            self.isLoading = false
        }
    }
    
    private func sendMessage() {
        guard !newMessageText.isEmpty,
              let currentUserId = authService.currentUserId else { return }
        
        let message = Message(
            id: UUID().uuidString,
            conversationId: conversation.id,
            senderId: currentUserId,
            receiverId: conversation.otherUserId,
            content: newMessageText,
            messageType: .text,
            timestamp: Date(),
            isEphemeral: true,
            isRead: false,
            viewDuration: 10.0
        )
        
        messages.append(message)
        newMessageText = ""
        
        // In real implementation, send via FirebaseMessagingService
        // messagingService.sendMessage(message)
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading) {
                if let content = message.content, !content.isEmpty {
                    Text(content)
                        .padding(12)
                        .background(isFromCurrentUser ? Color.yellow : Color(.systemGray5))
                        .foregroundColor(isFromCurrentUser ? .black : .primary)
                        .cornerRadius(16)
                }
                
                if let mediaURL = message.mediaURL {
                    AsyncImage(url: URL(string: mediaURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 150)
                            .overlay(
                                ProgressView()
                            )
                    }
                    .frame(maxWidth: 200, maxHeight: 150)
                    .cornerRadius(10)
                }
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(conversation.otherUserName.prefix(1).uppercased()))
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.otherUserName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack {
                    Text(conversation.lastMessageTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if conversation.unreadCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\\(conversation.unreadCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewChatView: View {
    let onUserSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var friends: [User] = []
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search friends...")
                
                List {
                    ForEach(filteredFriends) { friend in
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(friend.username.prefix(1).uppercased()))
                                        .foregroundColor(.white)
                                        .font(.headline)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(friend.displayName)
                                    .font(.headline)
                                
                                Text("@\\(friend.username)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onUserSelected(friend.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
        .onAppear {
            loadFriends()
        }
    }
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { friend in
                friend.username.localizedCaseInsensitiveContains(searchText) ||
                friend.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadFriends() {
        // Mock friends for demo
        friends = User.mockFriends
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    ConversationView(
        conversation: Conversation.mockConversations.first!,
        onBack: {}
    )
    .environmentObject(FirebaseMessagingService.shared)
    .environmentObject(FirebaseAuthService.shared)
}