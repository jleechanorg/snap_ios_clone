import SwiftUI
import FirebaseAuth

struct RealProfileView: View {
    @EnvironmentObject var authViewModel: RealAuthViewModel
    @State private var isEditingProfile = false
    @State private var showingSettings = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Header
            VStack(spacing: 16) {
                // Profile Image or Initials
                if let photoURL = authViewModel.currentUser?.photoURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        placeholderView
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    placeholderView
                }
                
                // User Info
                VStack(spacing: 8) {
                    if let displayName = authViewModel.currentUser?.displayName {
                        Text(displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    if let email = authViewModel.currentUser?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("@username")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20)
            
            // Stats Section
            LazyVGrid(columns: columns, spacing: 20) {
                StatCard(number: authViewModel.userStats.snapsSent, label: "Snaps Sent")
                StatCard(number: authViewModel.userStats.snapsReceived, label: "Snaps Received")
                StatCard(number: authViewModel.userStats.friendsCount, label: "Friends")
                StatCard(number: authViewModel.userStats.currentStreak, label: "Streak")
                StatCard(number: authViewModel.userStats.snapScore, label: "Score")
            }
            .padding()
            
            Spacer()
            
            // Buttons Section
            VStack(spacing: 16) {
                Button("Edit Profile") {
                    isEditingProfile = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Settings") {
                    showingSettings = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
                
                Button("Sign Out") {
                    Task {
                        await authViewModel.signOut()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationTitle("Profile")
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
            if let initials = authViewModel.currentUser?.displayName?.prefix(2) {
                Text(String(initials))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .frame(width: 100, height: 100)
    }
}

struct StatCard: View {
    let number: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}