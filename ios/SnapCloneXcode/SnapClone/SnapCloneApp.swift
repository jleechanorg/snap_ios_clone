import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@main
struct SnapCloneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Initialize ViewModels
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    
    init() {
        // Configure app appearance for dark theme
        configureAppAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(cameraViewModel)
                .environmentObject(friendsViewModel)
                .preferredColorScheme(.dark)
        }
    }
    
    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.black
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        configureFirebase()
        return true
    }
    
    private func configureFirebase() {
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: plistPath) else {
            fatalError("Firebase configuration failed: GoogleService-Info.plist not found or invalid")
        }
        
        FirebaseApp.configure(options: options)
        
        // Enable Firestore offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
    }
}

