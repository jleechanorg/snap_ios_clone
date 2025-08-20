import SwiftUI

struct AddFriendsView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Search results
                if friendsViewModel.isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    EmptySearchView()
                } else if friendsViewModel.searchResults.isEmpty {
                    NoResultsView(searchText: searchText)
                } else {
                    SearchResultsList()
                }
                
                Spacer()
            }
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            friendsViewModel.searchText = newValue
        }
        .onDisappear {
            friendsViewModel.clearSearch()
        }
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Find Friends")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Search for friends by username or display name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                    Text("Search by username or name")
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(.blue)
                    Text("Scan QR code to add instantly")
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                    Text("Share your profile with others")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct NoResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No users found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("No users found for \"\(searchText)\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("Try searching with a different username or display name")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SearchResultsList: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        List {
            ForEach(friendsViewModel.searchResults) { result in
                UserSearchRow(user: result)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct UserSearchRow: View {
    let user: UserSearchResult
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @State private var isProcessing = false
    
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
                            .font(.title2)
                            .fontWeight(.medium)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action button based on friendship status
            Group {
                switch friendsViewModel.getFriendshipStatus(for: user) {
                case .friends:
                    Text("Friends")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(15)
                
                case .requestSent:
                    Text("Requested")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                
                case .requestReceived:
                    Button("Accept") {
                        if let friend = friendsViewModel.friendRequests.first(where: { $0.id == user.id }) {
                            isProcessing = true
                            Task {
                                await friendsViewModel.acceptFriendRequest(from: friend)
                                isProcessing = false
                            }
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(15)
                    .disabled(isProcessing)
                
                case .none:
                    Button("Add") {
                        isProcessing = true
                        Task {
                            await friendsViewModel.sendFriendRequest(to: user)
                            isProcessing = false
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(15)
                    .disabled(isProcessing)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search username or name...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                }
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    AddFriendsView()
        .environmentObject(FriendsViewModel())
}