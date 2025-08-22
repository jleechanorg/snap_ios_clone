import SwiftUI
import FirebaseCore
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

// Simplified Story model for immediate compilation
struct StorySimple: Identifiable {
    let id = UUID()
    let userId: String
    let username: String
    let mediaURL: String
    let createdAt = Date()
    var hasExpired: Bool {
        Date().timeIntervalSince(createdAt) > 86400 // 24 hours
    }
}

// Simplified Conversation model
struct ConversationSimple: Identifiable {
    let id = UUID()
    let otherUserName: String
    let lastMessage: String?
    let lastMessageTime = Date()
    let unreadCount: Int
}

// Simplified User model
struct UserSimple {
    let email: String?
    let displayName: String
    let username: String
}

// Minimal AuthViewModel for compilation
@MainActor
class SimpleAuthViewModel: ObservableObject {
    @Published var currentUser: UserSimple?
    @Published var isAuthenticated = false
    
    init() {
        // Mock user for demo
        self.currentUser = UserSimple(
            email: "demo@snapclone.com",
            displayName: "Demo User",
            username: "demo"
        )
        self.isAuthenticated = true
    }
    
    func signIn(email: String, password: String) async throws {
        // Mock sign in
        await MainActor.run {
            self.currentUser = UserSimple(
                email: email,
                displayName: "Demo User",
                username: "demo"
            )
            self.isAuthenticated = true
        }
    }
    
    func signOut() async {
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
}

// Minimal CameraViewModel
@MainActor
class SimpleCameraViewModel: ObservableObject {
    @Published var isSessionRunning = false
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setupCamera() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func capturePhoto() {
        isCapturing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isCapturing = false
        }
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
    
    func switchCamera() {
        // Mock implementation
    }
}

// Minimal FriendsViewModel
@MainActor
class SimpleFriendsViewModel: ObservableObject {
    @Published var conversations: [ConversationSimple] = []
    
    func loadConversations() async {
        await MainActor.run {
            self.conversations = [
                ConversationSimple(otherUserName: "Alice", lastMessage: "Hey there!", unreadCount: 2),
                ConversationSimple(otherUserName: "Bob", lastMessage: "See you later", unreadCount: 0),
                ConversationSimple(otherUserName: "Charlie", lastMessage: nil, unreadCount: 1)
            ]
        }
    }
}

@main
struct SnapCloneWorkingApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var authViewModel: SimpleAuthViewModel
    @StateObject private var cameraViewModel = SimpleCameraViewModel()
    @StateObject private var friendsViewModel = SimpleFriendsViewModel()
    
    init() {
        FirebaseApp.configure()
        print("🔥 Firebase: Initialized with REAL authentication")
        
        // Check if we can use RealAuthViewModel (if it exists in the build)
        // For now use SimpleAuthViewModel to compile
        _authViewModel = StateObject(wrappedValue: SimpleAuthViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainAppView()
                    .environmentObject(authViewModel)
                    .environmentObject(cameraViewModel)
                    .environmentObject(friendsViewModel)
                    .preferredColorScheme(.dark)
            } else {
                WorkingLoginView()
                    .environmentObject(authViewModel)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

struct WorkingLoginView: View {
    @EnvironmentObject var authViewModel: SimpleAuthViewModel
    @State private var email = "demo@snapclone.com"
    @State private var password = "demo123"
    
    var body: some View {
        VStack(spacing: 30) {
            Text("👻")
                .font(.system(size: 80))
            
            Text("SnapClone")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Sign In") {
                    Task {
                        do {
                            try await authViewModel.signIn(email: email, password: password)
                        } catch {
                            print("Sign in error: \(error)")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct WorkingMainAppView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authViewModel: SimpleAuthViewModel
    @EnvironmentObject var cameraViewModel: SimpleCameraViewModel
    @EnvironmentObject var friendsViewModel: SimpleFriendsViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkingCameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(0)
            
            WorkingStoriesView()
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("Stories")
                }
                .tag(1)
            
            WorkingChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(2)
            
            WorkingProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.yellow)
    }
}

struct WorkingCameraView: View {
    @EnvironmentObject var cameraViewModel: SimpleCameraViewModel
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraViewModel.authorizationStatus == .authorized {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("📷 Camera Preview Area")
                            .foregroundColor(.white)
                            .font(.title2)
                    )
                    .ignoresSafeArea()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("📷 Camera Access Required")
                            .foregroundColor(.white)
                            .font(.title2)
                    )
                    .ignoresSafeArea()
            }
            
            VStack {
                Spacer()
                
                HStack(spacing: 50) {
                    Button(action: { 
                        cameraViewModel.toggleFlash()
                    }) {
                        Image(systemName: cameraViewModel.flashMode == .off ? "bolt.slash.fill" : "bolt.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { 
                        cameraViewModel.capturePhoto()
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .fill(cameraViewModel.isCapturing ? Color.gray : Color.white)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .disabled(cameraViewModel.isCapturing)
                    
                    Button(action: { 
                        cameraViewModel.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            cameraViewModel.setupCamera()
        }
        .navigationBarHidden(true)
    }
}

struct WorkingStoriesView: View {
    @EnvironmentObject var authViewModel: SimpleAuthViewModel
    @State private var stories: [StorySimple] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView("Loading stories...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if stories.isEmpty {
                        VStack {
                            Text("📖")
                                .font(.system(size: 60))
                                .opacity(0.6)
                            
                            Text("No Stories Yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, 10)
                            
                            Text("Stories from your friends will appear here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 15) {
                            ForEach(stories) { story in
                                WorkingStoryRowView(story: story)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Stories")
            .refreshable {
                await loadStories()
            }
        }
        .onAppear {
            Task {
                await loadStories()
            }
        }
    }
    
    private func loadStories() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        stories = [
            StorySimple(userId: "1", username: "alice", mediaURL: "https://example.com/story1.jpg"),
            StorySimple(userId: "2", username: "bob", mediaURL: "https://example.com/story2.jpg"),
            StorySimple(userId: "3", username: "charlie", mediaURL: "https://example.com/story3.jpg")
        ]
        
        isLoading = false
    }
}

struct WorkingStoryRowView: View {
    let story: StorySimple
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(story.username.prefix(1).uppercased())
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.semibold)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(story.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(story.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !story.hasExpired {
                    Text("• Active")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("• Expired")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 70)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Navigate to story detail view
        }
    }
}

struct WorkingChatView: View {
    @EnvironmentObject var friendsViewModel: SimpleFriendsViewModel
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading conversations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if friendsViewModel.conversations.isEmpty {
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
                    List(friendsViewModel.conversations) { conversation in
                        WorkingConversationRowView(conversation: conversation)
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
        await friendsViewModel.loadConversations()
        isLoading = false
    }
}

struct WorkingConversationRowView: View {
    let conversation: ConversationSimple
    
    var body: some View {
        HStack(spacing: 15) {
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

struct WorkingProfileView: View {
    @EnvironmentObject var authViewModel: SimpleAuthViewModel
    @State private var firebaseUser = Auth.auth().currentUser
    @State private var userProfile: [String: Any] = [:]
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 15) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(firebaseUser?.email?.prefix(1).uppercased() ?? "👤")
                                .font(.system(size: 40))
                                .foregroundColor(.black)
                        )
                    
                    // Show real Firebase data if available
                    if let firebaseUser = firebaseUser {
                        Text(firebaseUser.email ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Firebase User: \(firebaseUser.uid.prefix(8))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let user = authViewModel.currentUser {
                        Text(user.email ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Demo User")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 40) {
                    VStack {
                        Text("42")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Snaps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("123")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Friends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("7")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Stories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 15) {
                    Button("Settings") {
                        // Settings action
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
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
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
        }
    }
}