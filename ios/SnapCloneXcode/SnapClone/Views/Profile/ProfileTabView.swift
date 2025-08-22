import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileTabView: View {
    @State private var currentUser = Auth.auth().currentUser
    @State private var userProfile: [String: Any] = [:]
    @State private var userStats = UserStats()
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading profile...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Profile Header
                    VStack(spacing: 15) {
                        // Avatar
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(displayNameInitial)
                                    .font(.system(size: 40))
                                    .foregroundColor(.black)
                            )
                        
                        // User Info from Firebase
                        VStack(spacing: 5) {
                            Text(displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("@\(username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let email = currentUser?.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats Section
                    HStack(spacing: 30) {
                        StatView(value: "\(userStats.snapsSent)", label: "Sent")
                        StatView(value: "\(userStats.snapsReceived)", label: "Received")
                        StatView(value: "\(userStats.friendsCount)", label: "Friends")
                    }
                    .padding()
                    
                    HStack(spacing: 30) {
                        StatView(value: "🔥 \(userStats.currentStreak)", label: "Streak")
                        StatView(value: "\(userStats.snapScore)", label: "Score")
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: {}) {
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
                        
                        Button(action: signOut) {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private var displayName: String {
        userProfile["displayName"] as? String ?? currentUser?.displayName ?? "User"
    }
    
    private var username: String {
        userProfile["username"] as? String ?? currentUser?.email?.components(separatedBy: "@").first ?? "user"
    }
    
    private var displayNameInitial: String {
        String(displayName.prefix(1).uppercased())
    }
    
    private func loadUserData() {
        Task {
            guard let userId = currentUser?.uid else {
                isLoading = false
                return
            }
            
            // Fetch user profile
            do {
                let userDoc = try await db.collection("users").document(userId).getDocument()
                if userDoc.exists {
                    userProfile = userDoc.data() ?? [:]
                } else {
                    // Create profile if doesn't exist
                    let newProfile: [String: Any] = [
                        "uid": userId,
                        "email": currentUser?.email ?? "",
                        "displayName": currentUser?.displayName ?? "User",
                        "username": currentUser?.email?.components(separatedBy: "@").first ?? "user",
                        "createdAt": Date()
                    ]
                    try await db.collection("users").document(userId).setData(newProfile)
                    userProfile = newProfile
                }
                
                // Fetch or create user stats
                let statsDoc = try await db.collection("user_stats").document(userId).getDocument()
                if statsDoc.exists {
                    let data = statsDoc.data() ?? [:]
                    userStats = UserStats(
                        snapsSent: data["snapsSent"] as? Int ?? 0,
                        snapsReceived: data["snapsReceived"] as? Int ?? 0,
                        friendsCount: data["friendsCount"] as? Int ?? 0,
                        currentStreak: data["currentStreak"] as? Int ?? 0,
                        snapScore: data["snapScore"] as? Int ?? 0
                    )
                } else {
                    // Create default stats
                    let defaultStats: [String: Any] = [
                        "snapsSent": 0,
                        "snapsReceived": 0,
                        "friendsCount": 0,
                        "currentStreak": 0,
                        "snapScore": 0
                    ]
                    try await db.collection("user_stats").document(userId).setData(defaultStats)
                }
            } catch {
                print("Error loading user data: \(error)")
            }
            
            isLoading = false
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // App will automatically redirect to login
        } catch {
            print("Error signing out: \(error)")
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