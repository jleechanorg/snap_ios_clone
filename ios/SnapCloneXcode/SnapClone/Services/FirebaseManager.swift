//
//  FirebaseManager.swift
//  SnapClone
//
//  Production Firebase SDK implementation for iOS Snapchat Clone
//  Generated with Cerebras optimization for iOS best practices
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Production Firebase manager providing centralized access to Firebase services
/// Maintains same interface as mock implementation for TDD compatibility
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    // MARK: - Published Properties for SwiftUI Integration
    @Published var isConfigured = false
    @Published var currentUser: User?
    @Published var isAuthenticating = false
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    private init() {
        configureFirebase()
        setupAuthStateListener()
    }
    
    deinit {
        removeAuthStateListener()
    }
    
    // MARK: - Firebase Configuration
    
    /// Configure Firebase with comprehensive error handling and validation
    private func configureFirebase() {
        // Prevent duplicate configuration
        guard !isConfigured else { 
            print("⚠️ Firebase already configured")
            return 
        }
        
        // Validate GoogleService-Info.plist exists
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("❌ GoogleService-Info.plist not found - Firebase configuration failed")
            DispatchQueue.main.async {
                self.lastError = FirebaseConfigurationError.missingConfigFile
            }
            return
        }
        
        do {
            // Configure Firebase if not already configured
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
            
            // Validate Firebase app was created successfully
            guard FirebaseApp.app() != nil else {
                throw FirebaseConfigurationError.configurationFailed
            }
            
            DispatchQueue.main.async {
                self.isConfigured = true
                self.lastError = nil
                print("✅ Firebase configured successfully")
            }
            
        } catch {
            print("❌ Firebase configuration error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.lastError = error
                self.isConfigured = false
            }
        }
    }
    
    // MARK: - Authentication State Management
    
    /// Setup authentication state listener for real-time user updates
    private func setupAuthStateListener() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                if user != nil {
                    print("✅ User authenticated: \(user?.email ?? "Unknown")")
                } else {
                    print("👤 User signed out")
                }
            }
        }
    }
    
    /// Remove authentication state listener
    private func removeAuthStateListener() {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateDidChangeListenerHandle = nil
        }
    }
    
    // MARK: - Firebase Service Access
    // Maintains same interface as mock for TDD compatibility
    
    /// Firebase App instance - returns AnyObject for TDD compatibility
    var app: AnyObject? {
        return FirebaseApp.app()
    }
    
    /// Firebase Auth instance - returns AnyObject for TDD compatibility
    var auth: AnyObject? {
        guard isConfigured else { return nil }
        return Auth.auth()
    }
    
    /// Firebase Firestore instance - returns AnyObject for TDD compatibility
    var firestore: AnyObject? {
        guard isConfigured else { return nil }
        return Firestore.firestore()
    }
    
    /// Firebase Storage instance - returns AnyObject for TDD compatibility
    var storage: AnyObject? {
        guard isConfigured else { return nil }
        return Storage.storage()
    }
    
    // MARK: - Typed Service Access (for production use)
    
    /// Firebase Auth service with type safety
    var authService: Auth? {
        guard isConfigured else { return nil }
        return Auth.auth()
    }
    
    /// Firebase Firestore service with type safety
    var firestoreService: Firestore? {
        guard isConfigured else { return nil }
        return Firestore.firestore()
    }
    
    /// Firebase Storage service with type safety
    var storageService: Storage? {
        guard isConfigured else { return nil }
        return Storage.storage()
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> User {
        guard isConfigured else {
            throw FirebaseConfigurationError.notConfigured
        }
        
        DispatchQueue.main.async {
            self.isAuthenticating = true
        }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.isAuthenticating = false
                self.lastError = nil
            }
            return result.user
        } catch {
            DispatchQueue.main.async {
                self.isAuthenticating = false
                self.lastError = error
            }
            throw error
        }
    }
    
    /// Create new user account
    func createUser(email: String, password: String) async throws -> User {
        guard isConfigured else {
            throw FirebaseConfigurationError.notConfigured
        }
        
        DispatchQueue.main.async {
            self.isAuthenticating = true
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.isAuthenticating = false
                self.lastError = nil
            }
            return result.user
        } catch {
            DispatchQueue.main.async {
                self.isAuthenticating = false
                self.lastError = error
            }
            throw error
        }
    }
    
    /// Sign out current user
    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            self.lastError = nil
        }
    }
    
    // MARK: - Configuration Validation
    
    /// Validate Firebase configuration and services
    func validateConfiguration() -> Bool {
        guard isConfigured else {
            print("❌ Firebase not configured")
            return false
        }
        
        guard FirebaseApp.app() != nil else {
            print("❌ Firebase app not available")
            return false
        }
        
        print("✅ Firebase configuration validated")
        return true
    }
}

// MARK: - Firebase Configuration Errors

enum FirebaseConfigurationError: LocalizedError {
    case missingConfigFile
    case configurationFailed
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .missingConfigFile:
            return "GoogleService-Info.plist file not found"
        case .configurationFailed:
            return "Firebase configuration failed"
        case .notConfigured:
            return "Firebase not configured"
        }
    }
}