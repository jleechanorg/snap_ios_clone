import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom tab picker
                HStack(spacing: 0) {
                    TabButton(
                        title: "Chats",
                        badge: nil,
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        title: "Friends",
                        badge: nil,
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                    
                    TabButton(
                        title: "Requests",
                        badge: friendsViewModel.friendRequests.count > 0 ? friendsViewModel.friendRequests.count : nil,
                        isSelected: selectedTab == 2
                    ) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        ChatsView()
                    case 1:
                        FriendsView()
                    case 2:
                        RequestsView()
                    default:
                        ChatsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            friendsViewModel.showAddFriends()
                        }) {
                            Label("Add Friends", systemImage: "person.badge.plus")
                        }
                        
                        Button(action: {
                            friendsViewModel.toggleOnlineFilter()
                        }) {
                            Label(
                                friendsViewModel.showOnlineOnly ? "Show All" : "Show Online Only",
                                systemImage: "circle.fill"
                            )
                        }
                        
                        Menu("Sort By") {
                            ForEach(FriendSortOption.allCases, id: \.self) { option in
                                Button(option.displayName) {
                                    friendsViewModel.setSortOption(option)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                friendsViewModel.refresh()
            }
        }
        .sheet(isPresented: $friendsViewModel.showingAddFriends) {
            AddFriendsView()
        }
        .sheet(isPresented: $friendsViewModel.showingFriendProfile) {
            if let friend = friendsViewModel.selectedFriend {
                FriendProfileView(friend: friend)
            }
        }
        .alert("Error", isPresented: $friendsViewModel.showError) {
            Button("OK") {
                friendsViewModel.dismissError()
            }
        } message: {
            Text(friendsViewModel.errorMessage ?? "")
        }
        .onAppear {
            friendsViewModel.loadInitialData()
        }
    }
}

struct TabButton: View {
    let title: String
    let badge: Int?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(isSelected ? .semibold : .medium)
                
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? .blue : .clear),
                alignment: .bottom
            )
        }
    }
}

struct ChatsView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        Group {
            if friendsViewModel.conversations.isEmpty {
                EmptyStateView(
                    icon: "message",
                    title: "No Chats",
                    subtitle: "Start a conversation with your friends"
                ) {
                    Button("Add Friends") {
                        friendsViewModel.showAddFriends()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(friendsViewModel.conversations) { conversation in
                        ConversationRow(conversation: conversation)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .overlay {
            if friendsViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
    }
}

struct FriendsView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        Group {
            if friendsViewModel.friends.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Friends",
                    subtitle: "Add friends to start sharing photos"
                ) {
                    Button("Add Friends") {
                        friendsViewModel.showAddFriends()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(friendsViewModel.friends) { friend in
                        FriendRow(friend: friend)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .overlay {
            if friendsViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
    }
}

struct RequestsView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        Group {
            if friendsViewModel.friendRequests.isEmpty && friendsViewModel.sentRequests.isEmpty {
                EmptyStateView(
                    icon: "person.badge.plus",
                    title: "No Requests",
                    subtitle: "Friend requests will appear here"
                )
            } else {
                List {
                    if !friendsViewModel.friendRequests.isEmpty {
                        Section("Received Requests") {
                            ForEach(friendsViewModel.friendRequests) { request in
                                FriendRequestRow(user: request)
                            }
                        }
                    }
                    
                    if !friendsViewModel.sentRequests.isEmpty {
                        Section("Sent Requests") {
                            ForEach(friendsViewModel.sentRequests) { request in
                                SentRequestRow(user: request)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .overlay {
            if friendsViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack {
            // Profile image placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("U")
                        .font(.title2)
                        .fontWeight(.medium)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Friend Name")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(conversation.lastMessageTimestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Last message preview...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Unread indicator
            if conversation.unreadCount.values.first ?? 0 > 0 {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FriendRow: View {
    let friend: User
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        HStack {
            // Profile image
            AsyncImage(url: URL(string: friend.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(friend.displayName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.medium)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("@\(friend.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if friend.isOnline {
                        Text("• Online")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("• \(friend.lastSeen, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await friendsViewModel.startConversation(with: friend)
                }
            }) {
                Image(systemName: "message")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("View Profile") {
                friendsViewModel.showFriendProfile(friend)
            }
            
            Button("Remove Friend", role: .destructive) {
                Task {
                    await friendsViewModel.removeFriend(friend)
                }
            }
            
            Button("Block User", role: .destructive) {
                Task {
                    await friendsViewModel.blockUser(friend)
                }
            }
        }
    }
}

struct FriendRequestRow: View {
    let user: User
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        HStack {
            // Profile image
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(user.displayName.prefix(1)))
                            .font(.caption)
                            .fontWeight(.medium)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Accept") {
                    Task {
                        await friendsViewModel.acceptFriendRequest(from: user)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                
                Button("Decline") {
                    Task {
                        await friendsViewModel.declineFriendRequest(from: user)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(15)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SentRequestRow: View {
    let user: User
    
    var body: some View {
        HStack {
            // Profile image
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(user.displayName.prefix(1)))
                            .font(.caption)
                            .fontWeight(.medium)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Pending")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(15)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action {
                Button("Add Friends") {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    FriendsListView()
        .environmentObject(FriendsViewModel())
}