import SwiftUI

struct StoriesView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
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
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Load mock stories to demonstrate real data integration
        // In production, this would load from Firebase Storage
        guard let currentUser = firebaseManager.currentUser else {
            stories = []
            isLoading = false
            return
        }
        
        // Mock stories data to replace hardcoded ForEach(0..<10)
        stories = [
            Story(id: "1", username: "alice", timestamp: Date().addingTimeInterval(-3600), mediaURL: "https://example.com/story1.jpg", isExpired: false),
            Story(id: "2", username: "bob", timestamp: Date().addingTimeInterval(-7200), mediaURL: "https://example.com/story2.jpg", isExpired: false),
            Story(id: "3", username: "charlie", timestamp: Date().addingTimeInterval(-25200), mediaURL: "https://example.com/story3.jpg", isExpired: true)
        ]
        
        isLoading = false
    }
}

struct StoryRowView: View {
    let story: Story
    
    var body: some View {
        HStack(spacing: 15) {
            // User avatar placeholder
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
                
                Text(story.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !story.isExpired {
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
            
            // Story preview thumbnail
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

#Preview {
    StoriesView()
        .environmentObject(FirebaseManager.shared)
}