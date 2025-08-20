import SwiftUI

struct SharePhotoView: View {
    let image: UIImage
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFriends: Set<String> = []
    @State private var caption = ""
    @State private var viewDuration: TimeInterval = 10.0
    @State private var searchText = ""
    @State private var isSending = false
    
    private let viewDurations: [TimeInterval] = [3, 5, 10, 15, 30]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .clipped()
                    .background(Color.black)
                
                // Caption input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Add a caption...", text: $caption, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                
                // View duration selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("View Duration")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewDurations, id: \.self) { duration in
                                Button(action: {
                                    viewDuration = duration
                                }) {
                                    Text("\(Int(duration))s")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(viewDuration == duration ? Color.blue : Color.gray.opacity(0.2))
                                        )
                                        .foregroundColor(viewDuration == duration ? .white : .primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
                
                // Friends list
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Send to")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(selectedFriends.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // Friends list
                    List {
                        ForEach(filteredFriends, id: \.id) { friend in
                            FriendSelectRow(
                                friend: friend,
                                isSelected: selectedFriends.contains(friend.id ?? "")
                            ) { isSelected in
                                if let friendId = friend.id {
                                    if isSelected {
                                        selectedFriends.insert(friendId)
                                    } else {
                                        selectedFriends.remove(friendId)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Share Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendPhoto()
                    }
                    .disabled(selectedFriends.isEmpty || isSending)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            friendsViewModel.loadInitialData()
        }
    }
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friendsViewModel.friends
        } else {
            return friendsViewModel.friends.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func sendPhoto() {
        guard !selectedFriends.isEmpty else { return }
        
        isSending = true
        
        Task {
            for friendId in selectedFriends {
                do {
                    await cameraViewModel.sharePhoto(
                        image,
                        to: friendId,
                        caption: caption.isEmpty ? nil : caption
                    )
                } catch {
                    // Handle individual send failures
                    print("Failed to send to \(friendId): \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.isSending = false
                self.dismiss()
            }
        }
    }
}

struct FriendSelectRow: View {
    let friend: User
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
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
                            .font(.caption)
                            .fontWeight(.medium)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Friend info
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Online indicator
            if friend.isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
            
            // Selection indicator
            Button(action: {
                onSelectionChanged(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectionChanged(!isSelected)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search friends...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    SharePhotoView(image: UIImage(systemName: "photo") ?? UIImage())
        .environmentObject(FriendsViewModel())
        .environmentObject(CameraViewModel())
}