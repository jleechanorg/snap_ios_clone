import SwiftUI
import FirebaseCore

// Production Firebase implementation now in Services/FirebaseManager.swift
// Import FirebaseManager for app-wide Firebase access

@main
struct SnapCloneApp: App {
    init() {
        // Firebase configuration handled by FirebaseManager.shared
        // No need to call Firebase.configure() here as it's handled in FirebaseManager
        print("🔥 Production Firebase: Initialized via FirebaseManager")
    }
    
    var body: some Scene {
        WindowGroup {
            FirebaseTestView()
                .preferredColorScheme(.dark)
        }
    }
}

struct FirebaseTestView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔥 Production Firebase Test")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if firebaseManager.isConfigured {
                VStack(spacing: 10) {
                    Text("✅ Firebase SDK Configured")
                        .foregroundColor(.green)
                        .font(.headline)
                    
                    Text("Firebase App: \(firebaseManager.app != nil ? "Available" : "Not Available")")
                        .foregroundColor(.white)
                    
                    Text("Firebase Auth: \(firebaseManager.auth != nil ? "Available" : "Not Available")")
                        .foregroundColor(.white)
                    
                    Text("Firebase Firestore: \(firebaseManager.firestore != nil ? "Available" : "Not Available")")
                        .foregroundColor(.white)
                    
                    Text("Firebase Storage: \(firebaseManager.storage != nil ? "Available" : "Not Available")")
                        .foregroundColor(.white)
                    
                    if let user = firebaseManager.currentUser {
                        Text("👤 Authenticated: \(user.email ?? "Unknown")")
                            .foregroundColor(.blue)
                    } else {
                        Text("👤 Not Authenticated")
                            .foregroundColor(.orange)
                    }
                    
                    if firebaseManager.isAuthenticating {
                        ProgressView("Authenticating...")
                            .foregroundColor(.white)
                    }
                    
                    if let error = firebaseManager.lastError {
                        Text("⚠️ Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Text("🚀 Production Firebase SDK Active!")
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
            } else {
                VStack(spacing: 10) {
                    Text("❌ Firebase Configuration Failed")
                        .foregroundColor(.red)
                        .font(.headline)
                    
                    if let error = firebaseManager.lastError {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}