import SwiftUI
import FirebaseCore

// Production Firebase implementation now in Services/FirebaseManager.swift
// Import FirebaseManager for app-wide Firebase access

@main
struct SnapCloneApp: App {
    init() {
        // Initialize Firebase on app startup
        FirebaseApp.configure()
        print("🔥 Production Firebase: Configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            MainAppView(isAuthenticated: $isAuthenticated)
        } else {
            LoginView(isAuthenticated: $isAuthenticated)
        }
    }
}

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var autoSkipTimer: Timer?
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo
            VStack(spacing: 10) {
                Text("👻")
                    .font(.system(size: 80))
                
                Text("SnapClone")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Login Form
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Sign In") {
                    // For testing purposes, just authenticate
                    withAnimation {
                        isAuthenticated = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(10)
                .fontWeight(.bold)
                
                Button("Skip Authentication (Demo)") {
                    withAnimation {
                        isAuthenticated = true
                    }
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            // Auto-skip authentication after 3 seconds for testing
            autoSkipTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                withAnimation {
                    isAuthenticated = true
                }
            }
        }
        .onDisappear {
            autoSkipTimer?.invalidate()
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