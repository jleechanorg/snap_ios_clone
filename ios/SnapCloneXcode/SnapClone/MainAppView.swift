import SwiftUI

struct MainAppView: View {
    @State private var selectedTab = 0
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(0)
                .accessibilityIdentifier("CameraTab")
            
            StoriesView()
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("Stories")
                }
                .tag(1)
                .accessibilityIdentifier("StoriesTab")
            
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(2)
                .accessibilityIdentifier("ChatTab")
            
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
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack(spacing: 50) {
                    Button(action: {}) {
                        Image(systemName: "bolt.slash.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .accessibilityIdentifier("Flash")
                    
                    Button(action: {}) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .accessibilityIdentifier("Capture")
                    
                    Button(action: {}) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .accessibilityIdentifier("FlipCamera")
                }
                .padding(.bottom, 50)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Text("📸 Camera Ready")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

struct StoriesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Stories")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(0..<10) { index in
                            HStack {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text("👻")
                                            .font(.title2)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("Friend \(index + 1)")
                                        .font(.headline)
                                    Text("Posted 2h ago")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("View") {
                                    // View story action
                                }
                                .padding(.horizontal, 15)
                                .padding(.vertical, 5)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ChatView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Messages")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(0..<15) { index in
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("🙂")
                                            .font(.title3)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Friend \(index + 1)")
                                        .font(.headline)
                                    Text("Hey! What's up? 👋")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("2m")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if index % 3 == 0 {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    
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
                    
                    Text("jleechan")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("SnapClone User")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                            isAuthenticated = false
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
    MainAppView(isAuthenticated: .constant(true))
}