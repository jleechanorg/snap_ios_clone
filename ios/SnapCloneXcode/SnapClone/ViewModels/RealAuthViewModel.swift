// RealAuthViewModel.swift
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct UserStats {
    var snapsSent: Int = 0
    var snapsReceived: Int = 0
    var friendsCount: Int = 0
    var currentStreak: Int = 0
    var snapScore: Int = 0
}

@MainActor
class RealAuthViewModel: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var userProfile: [String: Any]?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userStats = UserStats()
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.currentUser = user
            self.isAuthenticated = user != nil
            
            if user != nil {
                Task {
                    await self.fetchUserProfile()
                    await self.updateUserStats()
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            isAuthenticated = true
            await fetchUserProfile()
            await updateUserStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, username: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = result.user
            isAuthenticated = true
            
            // Create user document in Firestore
            let userDoc = db.collection("users").document(result.user.uid)
            try await userDoc.setData([
                "uid": result.user.uid,
                "email": email,
                "username": username,
                "displayName": displayName,
                "createdAt": Timestamp(date: Date())
            ])
            
            await fetchUserProfile()
            await updateUserStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            userStats = UserStats()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    func fetchUserProfile() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if document.exists {
                self.userProfile = document.data()
            } else {
                // Create profile if doesn't exist
                let newProfile: [String: Any] = [
                    "uid": userId,
                    "email": currentUser?.email ?? "",
                    "displayName": currentUser?.displayName ?? "User",
                    "username": currentUser?.email?.components(separatedBy: "@").first ?? "user",
                    "createdAt": Date()
                ]
                try await db.collection("users").document(userId).setData(newProfile)
                self.userProfile = newProfile
            }
        } catch {
            errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
        }
    }
    
    func updateUserStats() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await db.collection("user_stats").document(userId).getDocument()
            if document.exists {
                let data = document.data()
                userStats = UserStats(
                    snapsSent: data?["snapsSent"] as? Int ?? 0,
                    snapsReceived: data?["snapsReceived"] as? Int ?? 0,
                    friendsCount: data?["friendsCount"] as? Int ?? 0,
                    currentStreak: data?["currentStreak"] as? Int ?? 0,
                    snapScore: data?["snapScore"] as? Int ?? 0
                )
            } else {
                // Create initial stats document
                let statsDoc = db.collection("user_stats").document(userId)
                try await statsDoc.setData([
                    "snapsSent": 0,
                    "snapsReceived": 0,
                    "friendsCount": 0,
                    "currentStreak": 0,
                    "snapScore": 0
                ])
                userStats = UserStats()
            }
        } catch {
            errorMessage = "Failed to update stats: \(error.localizedDescription)"
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}