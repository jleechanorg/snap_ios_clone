import Foundation
import SwiftUI
import Firebase
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var friends: [User] = []
    @Published var friendRequests: [User] = []
    @Published var sentRequests: [User] = []
    @Published var searchResults: [UserSearchResult] = []
    @Published var conversations: [Conversation] = []
    
    // UI State
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var searchText = ""
    @Published var selectedFriend: User?
    @Published var showingFriendProfile = false
    @Published var showingAddFriends = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Filter and sorting
    @Published var showOnlineOnly = false
    @Published var sortBy: FriendSortOption = .name
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol = FirebaseAuthService.shared
    private let messagingService: MessagingServiceProtocol = FirebaseMessagingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupSearchSubscription()
        loadInitialData()
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() {
        Task {
            await loadFriends()
            await loadFriendRequests()
            await loadConversations()
        }
    }
    
    @MainActor
    private func loadFriends() async {
        guard let currentUser = authService.getCurrentUser() else { return }
        
        isLoading = true
        
        do {
            let userProfile = try await FirebaseAuthService.shared.fetchUserProfile(by: currentUser.displayName ?? "")
            
            if let userProfile = userProfile {
                var friendUsers: [User] = []
                
                for friendId in userProfile.friends {
                    if let friend = try await fetchUserById(friendId) {
                        friendUsers.append(friend)
                    }
                }
                
                friends = sortFriends(friendUsers)
            }
        } catch {
            showErrorMessage("Failed to load friends: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadFriendRequests() async {
        guard let currentUser = authService.getCurrentUser() else { return }
        
        do {
            let userProfile = try await FirebaseAuthService.shared.fetchUserProfile(by: currentUser.displayName ?? "")
            
            if let userProfile = userProfile {
                var requestUsers: [User] = []
                
                for requesterId in userProfile.friendRequests {
                    if let requester = try await fetchUserById(requesterId) {
                        requestUsers.append(requester)
                    }
                }
                
                friendRequests = requestUsers
                
                // Load sent requests
                var sentRequestUsers: [User] = []
                for sentId in userProfile.sentRequests {
                    if let sentUser = try await fetchUserById(sentId) {
                        sentRequestUsers.append(sentUser)
                    }
                }
                
                sentRequests = sentRequestUsers
            }
        } catch {
            showErrorMessage("Failed to load friend requests: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadConversations() async {
        guard let currentUserId = authService.getCurrentUser()?.uid else { return }
        
        do {
            // This would typically use a real-time listener
            // For now, we'll create a simple implementation
            conversations = []
        } catch {
            showErrorMessage("Failed to load conversations: \(error.localizedDescription)")
        }
    }
    
    private func fetchUserById(_ userId: String) async throws -> User? {
        let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
        
        guard document.exists else { return nil }
        
        return try document.data(as: User.self)
    }
    
    // MARK: - Friend Management
    
    func sendFriendRequest(to user: UserSearchResult) async {
        guard let currentUserId = authService.getCurrentUser()?.uid else { return }
        
        isLoading = true
        
        do {
            // Add to current user's sent requests
            try await Firestore.firestore().collection("users").document(currentUserId).updateData([
                "sentRequests": FieldValue.arrayUnion([user.id])
            ])
            
            // Add to target user's friend requests
            try await Firestore.firestore().collection("users").document(user.id).updateData([
                "friendRequests": FieldValue.arrayUnion([currentUserId])
            ])
            
            // Update local state
            if let targetUser = try await fetchUserById(user.id) {
                sentRequests.append(targetUser)
            }
            
        } catch {
            showErrorMessage("Failed to send friend request: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func acceptFriendRequest(from user: User) async {
        guard let currentUserId = authService.getCurrentUser()?.uid,
              let friendId = user.id else { return }
        
        isLoading = true
        
        do {
            let batch = Firestore.firestore().batch()
            
            // Add to current user's friends and remove from requests
            let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
            batch.updateData([
                "friends": FieldValue.arrayUnion([friendId]),
                "friendRequests": FieldValue.arrayRemove([friendId])
            ], forDocument: currentUserRef)
            
            // Add to friend's friends and remove from sent requests
            let friendRef = Firestore.firestore().collection("users").document(friendId)
            batch.updateData([
                "friends": FieldValue.arrayUnion([currentUserId]),
                "sentRequests": FieldValue.arrayRemove([currentUserId])
            ], forDocument: friendRef)
            
            try await batch.commit()
            
            // Update local state
            friends.append(user)
            friendRequests.removeAll { $0.id == user.id }
            friends = sortFriends(friends)
            
        } catch {
            showErrorMessage("Failed to accept friend request: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func declineFriendRequest(from user: User) async {
        guard let currentUserId = authService.getCurrentUser()?.uid,
              let friendId = user.id else { return }
        
        isLoading = true
        
        do {
            let batch = Firestore.firestore().batch()
            
            // Remove from current user's requests
            let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
            batch.updateData([
                "friendRequests": FieldValue.arrayRemove([friendId])
            ], forDocument: currentUserRef)
            
            // Remove from friend's sent requests
            let friendRef = Firestore.firestore().collection("users").document(friendId)
            batch.updateData([
                "sentRequests": FieldValue.arrayRemove([currentUserId])
            ], forDocument: friendRef)
            
            try await batch.commit()
            
            // Update local state
            friendRequests.removeAll { $0.id == user.id }
            
        } catch {
            showErrorMessage("Failed to decline friend request: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func removeFriend(_ user: User) async {
        guard let currentUserId = authService.getCurrentUser()?.uid,
              let friendId = user.id else { return }
        
        isLoading = true
        
        do {
            let batch = Firestore.firestore().batch()
            
            // Remove from current user's friends
            let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
            batch.updateData([
                "friends": FieldValue.arrayRemove([friendId])
            ], forDocument: currentUserRef)
            
            // Remove from friend's friends
            let friendRef = Firestore.firestore().collection("users").document(friendId)
            batch.updateData([
                "friends": FieldValue.arrayRemove([currentUserId])
            ], forDocument: friendRef)
            
            try await batch.commit()
            
            // Update local state
            friends.removeAll { $0.id == user.id }
            
        } catch {
            showErrorMessage("Failed to remove friend: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func blockUser(_ user: User) async {
        // Implementation for blocking users
        // This would add the user to a blocked list and remove them from friends
        await removeFriend(user)
    }
    
    // MARK: - Search
    
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.searchUsers(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func searchUsers(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        do {
            searchResults = try await authService.searchUsers(query: query)
        } catch {
            showErrorMessage("Search failed: \(error.localizedDescription)")
            searchResults = []
        }
        
        isSearching = false
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
    }
    
    // MARK: - Sorting and Filtering
    
    private func sortFriends(_ friends: [User]) -> [User] {
        let filteredFriends = showOnlineOnly ? friends.filter { $0.isOnline } : friends
        
        switch sortBy {
        case .name:
            return filteredFriends.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .lastSeen:
            return filteredFriends.sorted { $0.lastSeen > $1.lastSeen }
        case .username:
            return filteredFriends.sorted { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
        }
    }
    
    func setSortOption(_ option: FriendSortOption) {
        sortBy = option
        friends = sortFriends(friends)
    }
    
    func toggleOnlineFilter() {
        showOnlineOnly.toggle()
        friends = sortFriends(friends)
    }
    
    // MARK: - Messaging
    
    func startConversation(with friend: User) async {
        guard let currentUserId = authService.getCurrentUser()?.uid,
              let friendId = friend.id else { return }
        
        do {
            let conversation = try await messagingService.getConversation(with: friendId)
            // Navigate to chat view (this would be handled by the navigation system)
        } catch {
            showErrorMessage("Failed to start conversation: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    func getFriendshipStatus(for user: UserSearchResult) -> FriendshipStatus {
        guard let currentUserId = authService.getCurrentUser()?.uid else { return .none }
        
        if friends.contains(where: { $0.id == user.id }) {
            return .friends
        } else if friendRequests.contains(where: { $0.id == user.id }) {
            return .requestReceived
        } else if sentRequests.contains(where: { $0.id == user.id }) {
            return .requestSent
        } else {
            return .none
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func dismissError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - UI Actions
    
    func showFriendProfile(_ friend: User) {
        selectedFriend = friend
        showingFriendProfile = true
    }
    
    func showAddFriends() {
        showingAddFriends = true
    }
    
    func refresh() {
        Task {
            await loadInitialData()
        }
    }
}

// MARK: - Supporting Types

enum FriendSortOption: String, CaseIterable {
    case name = "Name"
    case lastSeen = "Last Seen"
    case username = "Username"
    
    var displayName: String {
        return rawValue
    }
}