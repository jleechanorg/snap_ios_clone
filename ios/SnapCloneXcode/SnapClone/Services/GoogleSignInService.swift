import Foundation
import GoogleSignIn
import Firebase
import FirebaseAuth

class GoogleSignInService {
    static let shared = GoogleSignInService()
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["GOOGLE_APP_ID"] as? String else {
            print("❌ Failed to get Google Client ID from GoogleService-Info.plist")
            return
        }
        
        // Configure Google Sign-In
        if let config = GIDConfiguration(clientID: clientId) {
            GIDSignIn.sharedInstance.configuration = config
            print("✅ Google Sign-In configured successfully")
        }
    }
    
    // MARK: - Sign In Methods
    
    @MainActor
    func signIn() async throws -> User {
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            throw GoogleSignInError.noPresentingViewController
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                throw GoogleSignInError.noIDToken
            }
            
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in to Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            
            // Create or fetch user profile
            let userProfile = try await createOrFetchUserProfile(firebaseUser: firebaseUser, googleUser: user)
            
            return userProfile
            
        } catch {
            if let gidError = error as? GIDSignInError {
                throw GoogleSignInError.signInFailed(gidError.localizedDescription)
            } else if let authError = error as? AuthErrorCode {
                throw AuthError.from(authError)
            } else {
                throw GoogleSignInError.signInFailed(error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func signOut() async throws {
        // Sign out from Google
        GIDSignIn.sharedInstance.signOut()
        
        // Sign out from Firebase
        try Auth.auth().signOut()
    }
    
    // MARK: - User Profile Management
    
    private func createOrFetchUserProfile(firebaseUser: FirebaseAuth.User, googleUser: GIDGoogleUser) async throws -> User {
        let firestore = Firestore.firestore()
        
        // Check if user profile already exists
        let userDoc = try await firestore.collection("users").document(firebaseUser.uid).getDocument()
        
        if userDoc.exists {
            // User exists, return existing profile
            return try userDoc.data(as: User.self)
        } else {
            // Create new user profile
            let username = generateUsername(from: googleUser.profile?.email ?? "user")
            
            let newUser = User(
                id: firebaseUser.uid,
                username: username,
                email: googleUser.profile?.email ?? "",
                displayName: googleUser.profile?.name ?? username,
                profileImageURL: googleUser.profile?.imageURL(withDimension: 200)?.absoluteString,
                isOnline: true,
                lastSeen: Date(),
                joinedDate: Date(),
                authProvider: "google"
            )
            
            // Save to Firestore
            try await firestore.collection("users").document(firebaseUser.uid).setData(from: newUser)
            
            return newUser
        }
    }
    
    private func generateUsername(from email: String) -> String {
        let baseUsername = email.components(separatedBy: "@").first ?? "user"
        let cleanUsername = baseUsername.replacingOccurrences(of: ".", with: "")
                                      .replacingOccurrences(of: "+", with: "")
                                      .lowercased()
        
        // Add random suffix to ensure uniqueness
        let randomSuffix = String(Int.random(in: 1000...9999))
        return "\(cleanUsername)\(randomSuffix)"
    }
    
    // MARK: - Helper Methods
    
    func getCurrentGoogleUser() -> GIDGoogleUser? {
        return GIDSignIn.sharedInstance.currentUser
    }
    
    func hasValidGoogleSession() -> Bool {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            return false
        }
        
        // Check if tokens are still valid
        if let expirationDate = currentUser.accessToken.expirationDate {
            return expirationDate > Date()
        }
        
        return false
    }
    
    @MainActor
    func refreshTokenIfNeeded() async throws {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleSignInError.noCurrentUser
        }
        
        do {
            try await currentUser.refreshTokensIfNeeded()
        } catch {
            throw GoogleSignInError.tokenRefreshFailed(error.localizedDescription)
        }
    }
}

// MARK: - Google Sign-In Errors

enum GoogleSignInError: LocalizedError {
    case noPresentingViewController
    case noIDToken
    case noCurrentUser
    case signInFailed(String)
    case tokenRefreshFailed(String)
    case configurationFailed
    
    var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            return "No presenting view controller available"
        case .noIDToken:
            return "Failed to get ID token from Google"
        case .noCurrentUser:
            return "No current Google user found"
        case .signInFailed(let message):
            return "Google Sign-In failed: \(message)"
        case .tokenRefreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .configurationFailed:
            return "Google Sign-In configuration failed"
        }
    }
}

// MARK: - User Model Extension

extension User {
    init(id: String, username: String, email: String, displayName: String, profileImageURL: String? = nil, isOnline: Bool = false, lastSeen: Date = Date(), joinedDate: Date = Date(), authProvider: String = "google") {
        self.init()
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.joinedDate = joinedDate
        self.authProvider = authProvider
    }
}