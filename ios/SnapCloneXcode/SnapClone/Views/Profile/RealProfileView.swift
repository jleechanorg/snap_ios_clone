import SwiftUI
import Firebase

struct RealProfileView: View {
    @EnvironmentObject var authViewModel: RealAuthViewModel
    @State private var userStats = UserStats(snapsSent: 0, snapsReceived: 0, streak: 0, score: 0, friends: 0)
    @State private var isLoadingStats = true
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 15) {
                    // Avatar
                    if let photoURL = authViewModel.currentUser?.profileImageURL,
                       let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.yellow)
                                .overlay(
                                    Text(authViewModel.currentUser?.displayName.prefix(1).uppercased() ?? "?")
                                        .font(.system(size: 40))
                                        .foregroundColor(.black)
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(authViewModel.currentUser?.displayName.prefix(1).uppercased() ?? "👤")
                                    .font(.system(size: 40))
                                    .foregroundColor(.black)
                            )
                    }
                    
                    // User Info
                    VStack(spacing: 5) {
                        Text(authViewModel.currentUser?.displayName ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("@\(authViewModel.currentUser?.username ?? "username")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if let email = authViewModel.firebaseUser?.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    
                    // Edit Profile Button
                    Button(action: { showingEditProfile = true }) {
                        Text("Edit Profile")
                            .font(.caption)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(15)
                    }
                }
                .padding(.top, 20)
                
                // Stats Section
                if isLoadingStats {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                        .padding()
                } else {
                    HStack(spacing: 30) {
                        StatView(value: "\(userStats.snapsSent)", label: "Snaps Sent")
                        StatView(value: "\(userStats.snapsReceived)", label: "Received")
                        StatView(value: "\(userStats.friends)", label: "Friends")
                    }
                    .padding()
                    
                    HStack(spacing: 30) {
                        StatView(value: "🔥 \(userStats.streak)", label: "Streak")
                        StatView(value: "\(userStats.score)", label: "Score")
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: { showingSettings = true }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        Task {
                            await authViewModel.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Sign Out")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .onAppear {
            loadUserStats()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authViewModel)
        }
    }
    
    private func loadUserStats() {
        Task {
            do {
                isLoadingStats = true
                userStats = try await authViewModel.getUserStats()
                isLoadingStats = false
            } catch {
                print("Error loading stats: \(error)")
                isLoadingStats = false
            }
        }
    }
}

struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// Placeholder views - implement these later
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    Text("Privacy")
                    Text("Security")
                    Text("Notifications")
                }
                Section("About") {
                    Text("Version 1.0.0")
                    Text("Terms of Service")
                    Text("Privacy Policy")
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: RealAuthViewModel
    @State private var displayName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display Name") {
                    TextField("Display Name", text: $displayName)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        try? await authViewModel.updateProfile(displayName: displayName, photoURL: nil)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .onAppear {
            displayName = authViewModel.currentUser?.displayName ?? ""
        }
    }
}