import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
            } else {
                AuthenticationView()
            }
        }
        .onAppear {
            authViewModel.checkAuthenticationStatus()
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var cameraViewModel: CameraViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat/Friends Tab
            FriendsListView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(0)
            
            // Camera Tab
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(1)
            
            // Stories Tab (simplified for MVP)
            StoriesView()
                .tabItem {
                    Image(systemName: "play.circle.fill")
                    Text("Stories")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.yellow)
        .preferredColorScheme(.dark)
        .onAppear {
            // Start camera session when app loads
            cameraViewModel.setupCamera()
        }
    }
}

// Placeholder Stories View for MVP
struct StoriesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Stories Coming Soon")
                    .foregroundColor(.white)
                    .font(.title2)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Stories")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(CameraViewModel())
        .environmentObject(FriendsViewModel())
}