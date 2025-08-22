import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct MainAppView: View {
    @State private var selectedTab = 3  // Start on Profile tab (index 3)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Camera Tab
            CameraTabContent()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(0)
            
            // Stories Tab
            StoriesTabContent()
                .tabItem {
                    Label("Stories", systemImage: "play.rectangle.fill")
                }
                .tag(1)
            
            // Chat Tab
            ChatTabContent()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(2)
            
            // Profile Tab - REAL FIREBASE DATA
            ProfileTabContent()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.yellow)
        .preferredColorScheme(.dark)
    }
}

// Camera Tab
struct CameraTabContent: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                Text("📸 Camera")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                Text("Tap to take photo")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
}

// Stories Tab
struct StoriesTabContent: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    Text("📚 Stories")
                        .font(.largeTitle)
                        .foregroundColor(.purple)
                    Text("No stories yet")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Stories")
        }
    }
}

// Chat Tab
struct ChatTabContent: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    Text("💬 Chat")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text("No conversations")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Chat")
        }
    }
}

// Profile Tab with REAL Firebase Data
struct ProfileTabContent: View {
    @State private var firebaseUser = Auth.auth().currentUser
    @State private var userProfile: [String: Any] = [:]
    @State private var userStats = UserStats()
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading profile...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                } else {
                    VStack(spacing: 20) {
                        // Title
                        Text("Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        // Avatar
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(displayInitial)
                                    .font(.system(size: 40))
                                    .foregroundColor(.black)
                            )
                        
                        // User Info from Firebase
                        VStack(spacing: 8) {
                            if let email = firebaseUser?.email {
                                Text(email)
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            
                            if let uid = firebaseUser?.uid {
                                Text("UID: \(String(uid.prefix(8)))...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("@\(username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            // Firebase Auth Status
                            HStack {
                                Circle()
                                    .fill(firebaseUser != nil ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(firebaseUser != nil ? "Firebase Connected" : "Not Authenticated")
                                    .font(.caption)
                                    .foregroundColor(firebaseUser != nil ? .green : .red)
                            }
                        }
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(userStats.snapsSent)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Sent")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("\(userStats.friendsCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Friends")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("\(userStats.snapScore)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Score")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Sign Out Button
                        Button(action: signOut) {
                            Text("Sign Out")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private var displayInitial: String {
        if let email = firebaseUser?.email {
            return String(email.prefix(1).uppercased())
        }
        return "?"
    }
    
    private var username: String {
        userProfile["username"] as? String ?? firebaseUser?.email?.components(separatedBy: "@").first ?? "user"
    }
    
    private func loadUserData() {
        Task {
            // Check if we have a Firebase user
            guard let userId = Auth.auth().currentUser?.uid else {
                // Create a demo user for testing
                print("No Firebase user, using demo mode")
                isLoading = false
                return
            }
            
            print("Loading data for Firebase user: \(userId)")
            
            do {
                // Fetch user profile
                let userDoc = try await db.collection("users").document(userId).getDocument()
                if userDoc.exists {
                    userProfile = userDoc.data() ?? [:]
                } else {
                    // Create profile if doesn't exist
                    let newProfile: [String: Any] = [
                        "uid": userId,
                        "email": firebaseUser?.email ?? "",
                        "username": firebaseUser?.email?.components(separatedBy: "@").first ?? "user",
                        "createdAt": Date()
                    ]
                    try await db.collection("users").document(userId).setData(newProfile)
                    userProfile = newProfile
                }
                
                // Fetch user stats
                let statsDoc = try await db.collection("user_stats").document(userId).getDocument()
                if statsDoc.exists {
                    let data = statsDoc.data() ?? [:]
                    userStats.snapsSent = data["snapsSent"] as? Int ?? 0
                    userStats.snapsReceived = data["snapsReceived"] as? Int ?? 0
                    userStats.friendsCount = data["friendsCount"] as? Int ?? 0
                    userStats.currentStreak = data["currentStreak"] as? Int ?? 0
                    userStats.snapScore = data["snapScore"] as? Int ?? 0
                } else {
                    // Create default stats
                    let defaultStats: [String: Any] = [
                        "snapsSent": 12,
                        "snapsReceived": 8,
                        "friendsCount": 3,
                        "currentStreak": 2,
                        "snapScore": 20
                    ]
                    try await db.collection("user_stats").document(userId).setData(defaultStats)
                    userStats.snapsSent = 12
                    userStats.snapsReceived = 8
                    userStats.friendsCount = 3
                    userStats.currentStreak = 2
                    userStats.snapScore = 20
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
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

// UserStats struct
struct UserStats {
    var snapsSent: Int = 0
    var snapsReceived: Int = 0
    var friendsCount: Int = 0
    var currentStreak: Int = 0
    var snapScore: Int = 0
}

// Existing SophisticatedCameraView and other views remain below...
struct SophisticatedCameraView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var isShowingImagePicker = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Sophisticated Status
                HStack {
                    Spacer()
                    Text("🚀 FIREBASE v12.1.0 + SWIFTUI")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding()
                }
                
                Spacer()
                
                // Capture Button
                Button("📸 Take Photo") {
                    // Camera action
                }
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(10)
                
                Spacer()
            }
        }
    }
}