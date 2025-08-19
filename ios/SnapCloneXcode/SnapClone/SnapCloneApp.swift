import SwiftUI
import FirebaseCore

@main
struct SnapCloneApp: App {
    // Temporarily use FirebaseManager for auth until import issues resolved
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        // Firebase configuration handled by FirebaseManager.shared
        FirebaseApp.configure()
        print("🔥 Production Firebase: Initialized via FirebaseManager")
    }
    
    var body: some Scene {
        WindowGroup {
            if firebaseManager.currentUser != nil {
                MainAppView(isAuthenticated: .constant(true))
                    .preferredColorScheme(.dark)
            } else {
                SimpleLoginView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}

// Simple LoginView to fix compilation issues
struct SimpleLoginView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
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
                            try await firebaseManager.signIn(email: email, password: password)
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
                
                Button("Demo Mode") {
                    Task {
                        do {
                            try await firebaseManager.signIn(email: "demo@snapclone.com", password: "demo123")
                        } catch {
                            print("Demo sign in error: \(error)")
                        }
                    }
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .environmentObject(firebaseManager)
    }
}
