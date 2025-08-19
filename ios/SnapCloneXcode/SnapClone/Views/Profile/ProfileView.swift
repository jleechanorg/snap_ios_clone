import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingSettings = false
    @State private var showingImagePicker = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        VStack {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("Tap to add photo")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 3)
                            )
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.blue))
                                    .offset(x: 40, y: 40)
                            )
                        }
                        
                        // User Info
                        VStack(spacing: 8) {
                            Text(authViewModel.currentUser?.displayName ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("@\(authViewModel.currentUser?.username ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Joined \(authViewModel.currentUser?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button("Edit Profile") {
                                showingEditProfile = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Share Profile") {
                                shareProfile()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stats")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Friends",
                                value: "\(authViewModel.currentUser?.friends.count ?? 0)",
                                icon: "person.2.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Snaps Sent",
                                value: "42", // This would be tracked
                                icon: "camera.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Days Active",
                                value: "\(daysSinceJoined)",
                                icon: "calendar.badge.clock",
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            QuickActionRow(
                                icon: "person.badge.plus",
                                title: "Add Friends",
                                subtitle: "Find and add new friends",
                                color: .blue
                            ) {
                                // Navigate to add friends
                            }
                            
                            QuickActionRow(
                                icon: "qrcode.viewfinder",
                                title: "Scan QR Code",
                                subtitle: "Add friends quickly",
                                color: .purple
                            ) {
                                // Open QR scanner
                            }
                            
                            QuickActionRow(
                                icon: "gear",
                                title: "Settings",
                                subtitle: "Privacy, notifications, and more",
                                color: .gray
                            ) {
                                showingSettings = true
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Sign Out Button
                    Button(action: {
                        Task {
                            await authViewModel.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView { image in
                updateProfileImage(image)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
    }
    
    private var daysSinceJoined: Int {
        guard let createdAt = authViewModel.currentUser?.createdAt else { return 0 }
        return Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    private func shareProfile() {
        let profileURL = "snapclone://user/\(authViewModel.currentUser?.username ?? "")"
        let activityVC = UIActivityViewController(
            activityItems: [profileURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func updateProfileImage(_ image: UIImage) {
        // This would upload the image and update the user profile
        // Implementation would use Firebase Storage
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// Placeholder views for navigation
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Settings Coming Soon")
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Edit Profile Coming Soon")
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct FriendProfileView: View {
    let friend: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Friend Profile for \(friend.displayName)")
                .navigationTitle(friend.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationViewModel())
}