import SwiftUI
import AVFoundation
import Firebase
import FirebaseFirestore
import Combine

// Import all sophisticated ViewModels and Models
import Foundation

// Models are already defined in Models folder

// Embedded views for compilation - temporary until separate files are properly included
struct StoriesView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @State private var stories: [Story] = []
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
                                StoryRowView(story: story)
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
        
        // Simulate Firebase Storage loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard let currentUser = authViewModel.currentUser else {
            stories = []
            isLoading = false
            return
        }
        
        // Mock stories data - integrated with AuthenticationViewModel
        stories = [
            Story(userId: "1", username: "alice", mediaURL: "https://example.com/story1.jpg"),
            Story(userId: "2", username: "bob", mediaURL: "https://example.com/story2.jpg"),
            Story(userId: "3", username: "charlie", mediaURL: "https://example.com/story3.jpg")
        ]
        
        isLoading = false
    }
}

struct StoryRowView: View {
    let story: Story
    
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

struct ChatView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading conversations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if conversations.isEmpty {
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
                    List(conversations) { conversation in
                        NavigationLink(destination: ConversationDetailView(conversation: conversation)) {
                            ConversationRowView(conversation: conversation)
                        }
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
        
        // Use FriendsViewModel to load conversations
        await friendsViewModel.loadConversations()
        conversations = friendsViewModel.conversations
        
        isLoading = false
    }
}

struct ConversationDetailView: View {
    let conversation: Conversation
    
    var body: some View {
        Text("Conversation with \(conversation.otherUserName)")
            .navigationTitle("Chat")
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    
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

struct MainAppView: View {
    @State private var selectedTab = 0
    @Binding var isAuthenticated: Bool
    
    // Connect to sophisticated ViewModels from environment
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(0)
                .accessibilityIdentifier("CameraTab")
                .environmentObject(authViewModel)
                .environmentObject(cameraViewModel)
                .environmentObject(friendsViewModel)
            
            StoriesView()
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("Stories")
                }
                .tag(1)
                .accessibilityIdentifier("StoriesTab")
                .environmentObject(authViewModel)
                .environmentObject(cameraViewModel)
                .environmentObject(friendsViewModel)
            
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(2)
                .accessibilityIdentifier("ChatTab")
                .environmentObject(authViewModel)
                .environmentObject(cameraViewModel)
                .environmentObject(friendsViewModel)
            
            ProfileView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(3)
                .accessibilityIdentifier("ProfileTab")
        }
        .accentColor(.yellow)
        .accessibilityIdentifier("MainTabBar")
    }
}

struct CameraView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @State private var isCapturing = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Real camera preview - connect to CameraViewModel
            if cameraViewModel.authorizationStatus == .authorized {
                CameraPreviewRepresentable(cameraViewModel: cameraViewModel)
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
                    // Flash button - connect to real CameraViewModel
                    Button(action: { 
                        cameraViewModel.toggleFlash()
                    }) {
                        Image(systemName: cameraViewModel.flashMode == .off ? "bolt.slash.fill" : "bolt.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .accessibilityIdentifier("Flash")
                    
                    // Capture button - connect to real CameraViewModel
                    Button(action: { 
                        isCapturing.toggle()
                        cameraViewModel.capturePhoto()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isCapturing = false
                        }
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .fill(isCapturing ? Color.gray : Color.white)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .accessibilityIdentifier("Capture")
                    .disabled(cameraViewModel.isCapturing)
                    
                    // Switch camera button - connect to real CameraViewModel
                    Button(action: { 
                        cameraViewModel.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .accessibilityIdentifier("FlipCamera")
                }
                .padding(.bottom, 50)
            }
            
            // Camera status - ready for real integration
            VStack {
                HStack {
                    Spacer()
                    Text("📸 Real Camera Integration")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            cameraViewModel.setupCamera()
        }
        .navigationBarHidden(true)
    }
}

struct CameraPreviewRepresentable: UIViewRepresentable {
    @ObservedObject var cameraViewModel: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        if let previewLayer = cameraViewModel.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraViewModel.previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Profile Header
                VStack(spacing: 15) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text("😎")
                                .font(.system(size: 40))
                        )
                    
                    if let user = authViewModel.currentUser {
                        Text(user.email ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("SnapClone User")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("jleechan")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("SnapClone User")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats
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
                
                // Settings and Sign Out
                VStack(spacing: 15) {
                    Button("Settings") {
                        // Settings action
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button("Sign Out") {
                        withAnimation {
                            Task {
                                await authViewModel.signOut()
                                isAuthenticated = false
                            }
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

#Preview {
    MainAppView(isAuthenticated: Binding.constant(true))
        .environmentObject(AuthenticationViewModel())
        .environmentObject(CameraViewModel())
        .environmentObject(FriendsViewModel())
}