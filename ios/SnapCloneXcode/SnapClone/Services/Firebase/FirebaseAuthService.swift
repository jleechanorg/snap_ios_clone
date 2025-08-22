import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, username: String, displayName: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() -> FirebaseAuth.User?
    func resetPassword(email: String) async throws
    func updateProfile(displayName: String?, photoURL: URL?) async throws
    func deleteAccount() async throws
}

class FirebaseAuthService: AuthServiceProtocol {
    static let shared = FirebaseAuthService()
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Authentication Methods
    
    @MainActor
    func signIn(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return try await fetchUserProfile(uid: result.user.uid)
    }
    
    @MainActor
    func signUp(email: String, password: String, username: String, displayName: String) async throws -> User {
        // First check if username is available
        let isUsernameAvailable = try await checkUsernameAvailability(username: username)
        guard isUsernameAvailable else {
            throw AuthError.usernameNotAvailable
        }
        
        // Create Firebase user
        let result = try await auth.createUser(withEmail: email, password: password)
        let firebaseUser = result.user
        
        // Update Firebase profile
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        // Create user profile in Firestore
        let user = User(
            id: firebaseUser.uid,
            username: username, 
            email: email, 
            displayName: displayName
        )
        try await createUserProfile(user: user, uid: firebaseUser.uid)
        
        return user
    }
    
    func signOut() async throws {
        try auth.signOut()
    }
    
    func getCurrentUser() -> FirebaseAuth.User? {
        return auth.currentUser
    }
    
    var isAuthenticated: Bool {
        return auth.currentUser != nil
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    func updateProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = getCurrentUser() else {
            throw AuthError.userNotFound
        }
        
        let changeRequest = user.createProfileChangeRequest()
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        try await changeRequest.commitChanges()
        
        // Update Firestore profile
        if let displayName = displayName {
            try await firestore.collection("users").document(user.uid).updateData([
                "displayName": displayName
            ])
        }
        if let photoURL = photoURL {
            try await firestore.collection("users").document(user.uid).updateData([
                "profileImageURL": photoURL.absoluteString
            ])
        }
    }
    
    func deleteAccount() async throws {
        guard let user = getCurrentUser() else {
            throw AuthError.userNotFound
        }
        
        // Delete user profile from Firestore
        try await firestore.collection("users").document(user.uid).delete()
        
        // Delete Firebase user
        try await user.delete()
    }
    
    // MARK: - User Profile Management
    
    private func createUserProfile(user: User, uid: String) async throws {
        try await firestore.collection("users").document(uid).setData(user.toDictionary())
    }
    
    private func fetchUserProfile(uid: String) async throws -> User {
        let document = try await firestore.collection("users").document(uid).getDocument()
        
        guard document.exists else {
            throw AuthError.userNotFound
        }
        
        guard let user = User.from(document: document) else {
            throw AuthError.invalidUserData
        }
        return user
    }
    
    func fetchUserProfile(by username: String) async throws -> User? {
        let query = firestore.collection("users").whereField("username", isEqualTo: username)
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return User.from(document: document)
    }
    
    func updateUserProfile(_ user: User) async throws {
        try await firestore.collection("users").document(user.id).updateData(user.toDictionary())
    }
    
    // MARK: - Username Management
    
    private func checkUsernameAvailability(username: String) async throws -> Bool {
        let query = firestore.collection("users").whereField("username", isEqualTo: username)
        let snapshot = try await query.getDocuments()
        return snapshot.documents.isEmpty
    }
    
    // MARK: - User Search
    
    func searchUsers(query: String, excludeCurrentUser: Bool = true) async throws -> [UserSearchResult] {
        let currentUserId = getCurrentUser()?.uid
        
        // Search by username (case-insensitive)
        let usernameQuery = firestore.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("username", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
            .limit(to: 20)
        
        // Search by display name (case-insensitive)
        let displayNameQuery = firestore.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThanOrEqualTo: query + "\u{f8ff}")
            .limit(to: 20)
        
        let usernameSnapshot = try await usernameQuery.getDocuments()
        let displayNameSnapshot = try await displayNameQuery.getDocuments()
        
        var users: [User] = []
        
        // Combine results from both queries
        for document in usernameSnapshot.documents {
            if let user = User.from(document: document) {
                users.append(user)
            }
        }
        
        for document in displayNameSnapshot.documents {
            if let user = User.from(document: document),
               !users.contains(where: { $0.id == user.id }) {
                users.append(user)
            }
        }
        
        // Filter out current user if requested
        if excludeCurrentUser, let currentUserId = currentUserId {
            users = users.filter { $0.id != currentUserId }
        }
        
        return users.map { UserSearchResult(from: $0) }
    }
    
    // MARK: - Online Status
    
    func updateOnlineStatus(isOnline: Bool) async throws {
        guard let userId = getCurrentUser()?.uid else { return }
        
        let updateData: [String: Any] = [
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: Date())
        ]
        
        try await firestore.collection("users").document(userId).updateData(updateData)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case userNotFound
    case usernameNotAvailable
    case invalidUserData
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case wrongPassword
    case userDisabled
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .usernameNotAvailable:
            return "Username is not available"
        case .invalidUserData:
            return "Invalid user data"
        case .emailAlreadyInUse:
            return "Email is already in use"
        case .weakPassword:
            return "Password is too weak"
        case .invalidEmail:
            return "Invalid email address"
        case .wrongPassword:
            return "Incorrect password"
        case .userDisabled:
            return "User account is disabled"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
    
    static func from(_ error: Error) -> AuthError {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .emailAlreadyInUse:
                return .emailAlreadyInUse
            case .weakPassword:
                return .weakPassword
            case .invalidEmail:
                return .invalidEmail
            case .wrongPassword:
                return .wrongPassword
            case .userDisabled:
                return .userDisabled
            case .networkError:
                return .networkError
            case .userNotFound:
                return .userNotFound
            default:
                return .unknown
            }
        }
        return .unknown
    }
}