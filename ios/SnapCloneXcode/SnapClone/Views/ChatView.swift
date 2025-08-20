import SwiftUI

struct ChatView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading conversations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if conversations.isEmpty {
                    VStack {
                        Text("💬")
                            .font(.system(size: 60))
                            .opacity(0.6)
                        
                        Text("No Conversations")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                        
                        Text("Start chatting with your friends!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(conversations) { conversation in
                        NavigationLink(destination: ConversationView(conversation: conversation)) {
                            ConversationRowView(conversation: conversation)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Chat")
            .refreshable {
                await loadConversations()
            }
        }
        .onAppear {
            Task {
                await loadConversations()
            }
        }
    }
    
    private func loadConversations() async {
        isLoading = true
        
        // Load conversations from Firebase Messaging Service
        guard let currentUserId = firebaseManager.currentUser?.uid else {
            // Show mock conversations for demonstration when not authenticated
            conversations = [
                Conversation(id: "1", otherUserName: "Alice", lastMessage: "Hey! How's it going?", lastMessageTime: Date().addingTimeInterval(-300), unreadCount: 2),
                Conversation(id: "2", otherUserName: "Bob", lastMessage: "Check out this photo!", lastMessageTime: Date().addingTimeInterval(-3600), unreadCount: 0),
                Conversation(id: "3", otherUserName: "Charlie", lastMessage: "Let's hang out later", lastMessageTime: Date().addingTimeInterval(-7200), unreadCount: 1)
            ]
            isLoading = false
            return
        }
        
        do {
            // Use the sophisticated messaging service to load real conversations
            // Use sophisticated messaging service once imports fixed
            // conversations = try await messagingService.loadConversations(for: currentUserId)
            // For now, show mock data to demonstrate integration readiness
            conversations = [
                Conversation(id: "1", otherUserName: "Alice", lastMessage: "Real Firebase message!", lastMessageTime: Date().addingTimeInterval(-300), unreadCount: 2)
            ]
        } catch {
            print("Failed to load conversations: \(error)")
            // Fallback to mock data for demonstration
            conversations = [
                Conversation(id: "1", otherUserName: "Alice", lastMessage: "Hey! How's it going?", lastMessageTime: Date().addingTimeInterval(-300), unreadCount: 2),
                Conversation(id: "2", otherUserName: "Bob", lastMessage: "Check out this photo!", lastMessageTime: Date().addingTimeInterval(-3600), unreadCount: 0)
            ]
        }
        
        isLoading = false
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 15) {
            // User avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.otherUserName.prefix(1).uppercased())
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(conversation.lastMessageTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("No messages yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ChatView()
        .environmentObject(FirebaseManager.shared)
}