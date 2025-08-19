//
//  FirebaseAuthService.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Complete Firebase authentication service with session management
//  Requirements: iOS 16+, Firebase Auth SDK
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Custom authentication errors
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password should be at least 6 characters long."
        case .userNotFound:
            return "No account found with this email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .emailAlreadyInUse:
            return "An account already exists with this email address."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .unknown(let message):
            return message
        }
    }
}

/// Firebase authentication service for user management
@MainActor
final class FirebaseAuthService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current authenticated user
    @Published var currentUser: User?
    
    /// Authentication state
    @Published var isAuthenticated = false
    
    /// Loading state for authentication operations
    @Published var isLoading = false
    
    /// Current authentication error
    @Published var authError: AuthError?
    
    // MARK: - Private Properties
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    static let shared = FirebaseAuthService()
    
    // MARK: - Initialization
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        removeAuthStateListener()
    }
    
    // MARK: - Authentication State Listener
    
    /// Set up authentication state listener
    private func setupAuthStateListener() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadUserData(for: user)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    /// Remove authentication state listener
    private func removeAuthStateListener() {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    /// Load user data from Firestore
    /// - Parameter firebaseUser: Firebase Auth user
    private func loadUserData(for firebaseUser: FirebaseAuth.User) async {
        do {
            let document = try await firestore.collection("users").document(firebaseUser.uid).getDocument()
            
            if let user = User.from(document: document) {
                self.currentUser = user
                self.isAuthenticated = true
                
                // Update user's online status
                user.setOnlineStatus(true)
                try await updateUserData(user)
            } else {
                // Create user document if it doesn't exist
                let newUser = User(
                    id: firebaseUser.uid,
                    username: firebaseUser.displayName ?? "User",
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName ?? "User"
                )
                
                try await createUserDocument(newUser)
                self.currentUser = newUser
                self.isAuthenticated = true
            }
        } catch {
            print("Error loading user data: \(error)")
            self.authError = .unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Throws: AuthError for authentication failures
    func signIn(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            print("User signed in: \(result.user.uid)")
        } catch {
            let authError = mapFirebaseError(error)
            self.authError = authError
            throw authError
        }
    }
    
    /// Sign up with email, password, and username
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - username: Desired username
    ///   - displayName: User's display name
    /// - Throws: AuthError for authentication failures
    func signUp(email: String, password: String, username: String, displayName: String? = nil) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        // Validate input
        guard isValidEmail(email) else {
            let error = AuthError.invalidEmail
            self.authError = error
            throw error
        }
        
        guard password.count >= 6 else {
            let error = AuthError.weakPassword
            self.authError = error
            throw error
        }
        
        do {
            // Check if username is available
            let isUsernameAvailable = try await checkUsernameAvailability(username)
            guard isUsernameAvailable else {
                let error = AuthError.unknown("Username is already taken")
                self.authError = error
                throw error
            }
            
            // Create authentication account
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Update user profile
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName ?? username
            try await changeRequest.commitChanges()
            
            // Create user document in Firestore
            let user = User(
                id: result.user.uid,
                username: username,
                email: email,
                displayName: displayName ?? username
            )
            
            try await createUserDocument(user)
            
            print("User created: \(result.user.uid)")
        } catch {
            let authError = mapFirebaseError(error)
            self.authError = authError
            throw authError
        }
    }
    
    /// Sign out the current user
    /// - Throws: AuthError for sign out failures
    func signOut() async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            // Update user's online status before signing out
            if let currentUser = currentUser {
                currentUser.setOnlineStatus(false)
                try await updateUserData(currentUser)
            }
            
            try auth.signOut()
            print("User signed out")
        } catch {
            let authError = mapFirebaseError(error)
            self.authError = authError
            throw authError
        }
    }
    
    /// Reset password for the given email
    /// - Parameter email: User's email address
    /// - Throws: AuthError for reset failures
    func resetPassword(email: String) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        guard isValidEmail(email) else {
            let error = AuthError.invalidEmail
            self.authError = error
            throw error
        }
        
        do {
            try await auth.sendPasswordReset(withEmail: email)
            print("Password reset email sent")
        } catch {
            let authError = mapFirebaseError(error)
            self.authError = authError
            throw authError
        }
    }
    
    /// Get the current authenticated user
    /// - Returns: Current user or nil if not authenticated
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    // MARK: - User Management
    
    /// Create user document in Firestore
    /// - Parameter user: User to create
    /// - Throws: Error if creation fails
    private func createUserDocument(_ user: User) async throws {
        try await firestore.collection("users").document(user.id).setData(user.toDictionary())
    }
    
    /// Update user data in Firestore
    /// - Parameter user: User to update
    /// - Throws: Error if update fails
    func updateUserData(_ user: User) async throws {
        try await firestore.collection("users").document(user.id).updateData(user.toDictionary())
    }
    
    /// Check if username is available
    /// - Parameter username: Username to check
    /// - Returns: True if username is available
    private func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let query = firestore.collection("users").whereField("username", isEqualTo: username)
        let snapshot = try await query.getDocuments()
        return snapshot.documents.isEmpty
    }
    
    /// Update user profile information
    /// - Parameters:
    ///   - displayName: New display name
    ///   - photoURL: New profile photo URL
    /// - Throws: Error if update fails
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        let changeRequest = firebaseUser.createProfileChangeRequest()
        
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        try await changeRequest.commitChanges()
        
        // Update local user data
        if let currentUser = currentUser {
            if let displayName = displayName {
                currentUser.displayName = displayName
            }
            
            if let photoURL = photoURL {
                currentUser.profileImageURL = photoURL.absoluteString
            }
            
            try await updateUserData(currentUser)
        }
    }
    
    /// Delete user account
    /// - Throws: AuthError for deletion failures
    func deleteAccount() async throws {
        guard let firebaseUser = auth.currentUser,
              let currentUser = currentUser else {
            throw AuthError.userNotFound
        }
        
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            // Delete user document from Firestore
            try await firestore.collection("users").document(currentUser.id).delete()
            
            // Delete Firebase Auth account
            try await firebaseUser.delete()
            
            print("User account deleted")
        } catch {
            let authError = mapFirebaseError(error)
            self.authError = authError
            throw authError
        }
    }
    
    // MARK: - Utility Methods
    
    /// Validate email format
    /// - Parameter email: Email to validate
    /// - Returns: True if email is valid
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Map Firebase error to custom AuthError
    /// - Parameter error: Firebase error
    /// - Returns: Mapped AuthError
    private func mapFirebaseError(_ error: Error) -> AuthError {
        guard let authErrorCode = AuthErrorCode.Code(rawValue: (error as NSError).code) else {
            return .unknown(error.localizedDescription)
        }
        
        switch authErrorCode {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .wrongPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    /// Clear authentication error
    func clearError() {
        authError = nil
    }
}

// MARK: - FirebaseAuthService Extensions

extension FirebaseAuthService {
    /// Check if user is authenticated
    var isUserAuthenticated: Bool {
        return auth.currentUser != nil && isAuthenticated
    }
    
    /// Get current user ID
    var currentUserId: String? {
        return currentUser?.id
    }
    
    /// Get current user email
    var currentUserEmail: String? {
        return currentUser?.email
    }
}