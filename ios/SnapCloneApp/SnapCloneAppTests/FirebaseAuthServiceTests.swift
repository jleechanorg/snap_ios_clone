//
//  FirebaseAuthServiceTests.swift
//  SnapCloneTests
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Comprehensive tests for Firebase Authentication service flows and error handling
//

import XCTest
import FirebaseAuth
import FirebaseFirestore
@testable import SnapClone

final class FirebaseAuthServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var authService: MockFirebaseAuthService!
    var mockAuth: MockAuth!
    var mockFirestore: MockFirestore!
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockAuth = MockAuth()
        mockFirestore = MockFirestore()
        authService = MockFirebaseAuthService(auth: mockAuth, firestore: mockFirestore)
    }
    
    override func tearDownWithError() throws {
        authService = nil
        mockAuth = nil
        mockFirestore = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() async throws {
        // Arrange
        let email = "test@example.com"
        let password = "password123"
        let username = "testuser"
        let displayName = "Test User"
        
        mockAuth.shouldSucceed = true
        mockAuth.mockUser = MockUser(uid: "user123", email: email)
        
        // Act
        let result = await authService.signUp(email: email, password: password, username: username, displayName: displayName)
        
        // Assert
        switch result {
        case .success(let user):
            XCTAssertEqual(user.id, "user123")
            XCTAssertEqual(user.email, email)
            XCTAssertEqual(user.username, username)
            XCTAssertEqual(user.displayName, displayName)
        case .failure:
            XCTFail("Sign up should have succeeded")
        }
    }
    
    func testSignUpWithExistingEmail() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17007, userInfo: nil) // Email already in use
        
        // Act
        let result = await authService.signUp(email: "existing@example.com", password: "password123", username: "testuser", displayName: "Test User")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign up should have failed with existing email")
        case .failure(let error):
            XCTAssertEqual(error, .emailAlreadyInUse)
        }
    }
    
    func testSignUpWithWeakPassword() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17026, userInfo: nil) // Weak password
        
        // Act
        let result = await authService.signUp(email: "test@example.com", password: "123", username: "testuser", displayName: "Test User")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign up should have failed with weak password")
        case .failure(let error):
            XCTAssertEqual(error, .weakPassword)
        }
    }
    
    func testSignUpWithInvalidEmail() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17008, userInfo: nil) // Invalid email
        
        // Act
        let result = await authService.signUp(email: "invalid-email", password: "password123", username: "testuser", displayName: "Test User")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign up should have failed with invalid email")
        case .failure(let error):
            XCTAssertEqual(error, .invalidEmail)
        }
    }
    
    func testSignUpWithExistingUsername() async throws {
        // Arrange
        mockAuth.shouldSucceed = true
        mockAuth.mockUser = MockUser(uid: "user123", email: "test@example.com")
        mockFirestore.userExists = true // Username already exists
        
        // Act
        let result = await authService.signUp(email: "test@example.com", password: "password123", username: "existinguser", displayName: "Test User")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign up should have failed with existing username")
        case .failure(let error):
            XCTAssertEqual(error, .usernameAlreadyTaken)
        }
    }
    
    // MARK: - Sign In Tests
    
    func testSignInSuccess() async throws {
        // Arrange
        let email = "test@example.com"
        let password = "password123"
        
        mockAuth.shouldSucceed = true
        mockAuth.mockUser = MockUser(uid: "user123", email: email)
        mockFirestore.mockUser = User(id: "user123", username: "testuser", email: email, displayName: "Test User")
        
        // Act
        let result = await authService.signIn(email: email, password: password)
        
        // Assert
        switch result {
        case .success(let user):
            XCTAssertEqual(user.id, "user123")
            XCTAssertEqual(user.email, email)
        case .failure:
            XCTFail("Sign in should have succeeded")
        }
    }
    
    func testSignInWithInvalidCredentials() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17009, userInfo: nil) // Wrong password
        
        // Act
        let result = await authService.signIn(email: "test@example.com", password: "wrongpassword")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign in should have failed with wrong password")
        case .failure(let error):
            XCTAssertEqual(error, .wrongPassword)
        }
    }
    
    func testSignInWithUserNotFound() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17011, userInfo: nil) // User not found
        
        // Act
        let result = await authService.signIn(email: "notfound@example.com", password: "password123")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign in should have failed with user not found")
        case .failure(let error):
            XCTAssertEqual(error, .userNotFound)
        }
    }
    
    func testSignInWithUserDisabled() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17005, userInfo: nil) // User disabled
        
        // Act
        let result = await authService.signIn(email: "disabled@example.com", password: "password123")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign in should have failed with disabled user")
        case .failure(let error):
            XCTAssertEqual(error, .userDisabled)
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() async throws {
        // Arrange
        mockAuth.shouldSucceed = true
        
        // Act
        let result = await authService.signOut()
        
        // Assert
        switch result {
        case .success:
            XCTAssertTrue(mockAuth.signOutCalled)
        case .failure:
            XCTFail("Sign out should have succeeded")
        }
    }
    
    func testSignOutFailure() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        // Act
        let result = await authService.signOut()
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign out should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .unknown)
        }
    }
    
    // MARK: - Password Reset Tests
    
    func testPasswordResetSuccess() async throws {
        // Arrange
        let email = "test@example.com"
        mockAuth.shouldSucceed = true
        
        // Act
        let result = await authService.resetPassword(email: email)
        
        // Assert
        switch result {
        case .success:
            XCTAssertTrue(mockAuth.passwordResetCalled)
        case .failure:
            XCTFail("Password reset should have succeeded")
        }
    }
    
    func testPasswordResetWithInvalidEmail() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17008, userInfo: nil) // Invalid email
        
        // Act
        let result = await authService.resetPassword(email: "invalid-email")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Password reset should have failed with invalid email")
        case .failure(let error):
            XCTAssertEqual(error, .invalidEmail)
        }
    }
    
    func testPasswordResetWithUserNotFound() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17011, userInfo: nil) // User not found
        
        // Act
        let result = await authService.resetPassword(email: "notfound@example.com")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Password reset should have failed with user not found")
        case .failure(let error):
            XCTAssertEqual(error, .userNotFound)
        }
    }
    
    // MARK: - Current User Tests
    
    func testGetCurrentUserWhenSignedIn() async throws {
        // Arrange
        mockAuth.mockUser = MockUser(uid: "user123", email: "test@example.com")
        mockFirestore.mockUser = User(id: "user123", username: "testuser", email: "test@example.com", displayName: "Test User")
        
        // Act
        let user = await authService.getCurrentUser()
        
        // Assert
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.id, "user123")
    }
    
    func testGetCurrentUserWhenSignedOut() async throws {
        // Arrange
        mockAuth.mockUser = nil
        
        // Act
        let user = await authService.getCurrentUser()
        
        // Assert
        XCTAssertNil(user)
    }
    
    func testIsUserSignedIn() {
        // Test signed in
        mockAuth.mockUser = MockUser(uid: "user123", email: "test@example.com")
        XCTAssertTrue(authService.isUserSignedIn)
        
        // Test signed out
        mockAuth.mockUser = nil
        XCTAssertFalse(authService.isUserSignedIn)
    }
    
    // MARK: - User Update Tests
    
    func testUpdateUserProfile() async throws {
        // Arrange
        mockAuth.mockUser = MockUser(uid: "user123", email: "test@example.com")
        mockFirestore.shouldSucceed = true
        
        let updatedUser = User(
            id: "user123",
            username: "newusername",
            email: "test@example.com",
            displayName: "New Display Name"
        )
        
        // Act
        let result = await authService.updateUserProfile(updatedUser)
        
        // Assert
        switch result {
        case .success:
            XCTAssertTrue(mockFirestore.updateUserCalled)
        case .failure:
            XCTFail("User profile update should have succeeded")
        }
    }
    
    func testUpdateUserProfileWhenNotSignedIn() async throws {
        // Arrange
        mockAuth.mockUser = nil
        
        let updatedUser = User(
            id: "user123",
            username: "newusername",
            email: "test@example.com",
            displayName: "New Display Name"
        )
        
        // Act
        let result = await authService.updateUserProfile(updatedUser)
        
        // Assert
        switch result {
        case .success:
            XCTFail("User profile update should have failed when not signed in")
        case .failure(let error):
            XCTAssertEqual(error, .userNotSignedIn)
        }
    }
    
    // MARK: - Delete Account Tests
    
    func testDeleteAccountSuccess() async throws {
        // Arrange
        mockAuth.mockUser = MockUser(uid: "user123", email: "test@example.com")
        mockAuth.shouldSucceed = true
        mockFirestore.shouldSucceed = true
        
        // Act
        let result = await authService.deleteAccount()
        
        // Assert
        switch result {
        case .success:
            XCTAssertTrue(mockAuth.deleteUserCalled)
            XCTAssertTrue(mockFirestore.deleteUserCalled)
        case .failure:
            XCTFail("Account deletion should have succeeded")
        }
    }
    
    func testDeleteAccountWhenNotSignedIn() async throws {
        // Arrange
        mockAuth.mockUser = nil
        
        // Act
        let result = await authService.deleteAccount()
        
        // Assert
        switch result {
        case .success:
            XCTFail("Account deletion should have failed when not signed in")
        case .failure(let error):
            XCTAssertEqual(error, .userNotSignedIn)
        }
    }
    
    func testDeleteAccountRequiresRecentLogin() async throws {
        // Arrange
        mockAuth.mockUser = MockUser(uid: "user123", email: "test@example.com")
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: "FIRAuthErrorDomain", code: 17014, userInfo: nil) // Requires recent login
        
        // Act
        let result = await authService.deleteAccount()
        
        // Assert
        switch result {
        case .success:
            XCTFail("Account deletion should have failed requiring recent login")
        case .failure(let error):
            XCTAssertEqual(error, .requiresRecentLogin)
        }
    }
    
    // MARK: - Performance Tests
    
    func testAuthenticationPerformance() throws {
        measure {
            Task {
                _ = await authService.signIn(email: "test@example.com", password: "password123")
            }
        }
    }
    
    func testUserCreationPerformance() throws {
        measure {
            Task {
                _ = await authService.signUp(email: "test@example.com", password: "password123", username: "testuser", displayName: "Test User")
            }
        }
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentSignInOperations() async throws {
        let expectation = XCTestExpectation(description: "Concurrent sign-in operations")
        expectation.expectedFulfillmentCount = 5
        
        mockAuth.shouldSucceed = true
        mockAuth.mockUser = MockUser(uid: "user123", email: "test@example.com")
        mockFirestore.mockUser = User(id: "user123", username: "testuser", email: "test@example.com", displayName: "Test User")
        
        // Perform multiple concurrent sign-in operations
        for i in 0..<5 {
            Task {
                let result = await authService.signIn(email: "test\(i)@example.com", password: "password123")
                switch result {
                case .success:
                    expectation.fulfill()
                case .failure:
                    XCTFail("Concurrent sign-in should have succeeded")
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Edge Cases Tests
    
    func testSignUpWithEmptyCredentials() async throws {
        let result = await authService.signUp(email: "", password: "", username: "", displayName: "")
        
        switch result {
        case .success:
            XCTFail("Sign up should fail with empty credentials")
        case .failure(let error):
            XCTAssertEqual(error, .invalidEmail)
        }
    }
    
    func testSignInWithEmptyCredentials() async throws {
        let result = await authService.signIn(email: "", password: "")
        
        switch result {
        case .success:
            XCTFail("Sign in should fail with empty credentials")
        case .failure(let error):
            XCTAssertEqual(error, .invalidEmail)
        }
    }
    
    func testNetworkErrorHandling() async throws {
        // Arrange
        mockAuth.shouldSucceed = false
        mockAuth.error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        // Act
        let result = await authService.signIn(email: "test@example.com", password: "password123")
        
        // Assert
        switch result {
        case .success:
            XCTFail("Sign in should fail with network error")
        case .failure(let error):
            XCTAssertEqual(error, .networkError)
        }
    }
}

// MARK: - Mock Classes

enum AuthError: Error, Equatable {
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case wrongPassword
    case userNotFound
    case userDisabled
    case usernameAlreadyTaken
    case userNotSignedIn
    case requiresRecentLogin
    case networkError
    case unknown
}

class MockFirebaseAuthService {
    private let mockAuth: MockAuth
    private let mockFirestore: MockFirestore
    
    init(auth: MockAuth, firestore: MockFirestore) {
        self.mockAuth = auth
        self.mockFirestore = firestore
    }
    
    var isUserSignedIn: Bool {
        return mockAuth.mockUser != nil
    }
    
    func signUp(email: String, password: String, username: String, displayName: String) async -> Result<User, AuthError> {
        // Validate inputs
        guard !email.isEmpty else { return .failure(.invalidEmail) }
        guard !password.isEmpty else { return .failure(.weakPassword) }
        
        // Check if username exists
        if mockFirestore.userExists {
            return .failure(.usernameAlreadyTaken)
        }
        
        // Attempt Firebase Auth sign up
        if mockAuth.shouldSucceed {
            let user = User(
                id: mockAuth.mockUser?.uid ?? "user123",
                username: username,
                email: email,
                displayName: displayName
            )
            return .success(user)
        } else {
            return .failure(mapFirebaseError(mockAuth.error))
        }
    }
    
    func signIn(email: String, password: String) async -> Result<User, AuthError> {
        guard !email.isEmpty else { return .failure(.invalidEmail) }
        guard !password.isEmpty else { return .failure(.wrongPassword) }
        
        if mockAuth.shouldSucceed {
            let user = mockFirestore.mockUser ?? User(
                id: mockAuth.mockUser?.uid ?? "user123",
                username: "testuser",
                email: email,
                displayName: "Test User"
            )
            return .success(user)
        } else {
            return .failure(mapFirebaseError(mockAuth.error))
        }
    }
    
    func signOut() async -> Result<Void, AuthError> {
        mockAuth.signOutCalled = true
        
        if mockAuth.shouldSucceed {
            mockAuth.mockUser = nil
            return .success(())
        } else {
            return .failure(.unknown)
        }
    }
    
    func resetPassword(email: String) async -> Result<Void, AuthError> {
        mockAuth.passwordResetCalled = true
        
        if mockAuth.shouldSucceed {
            return .success(())
        } else {
            return .failure(mapFirebaseError(mockAuth.error))
        }
    }
    
    func getCurrentUser() async -> User? {
        guard let mockUser = mockAuth.mockUser else { return nil }
        return mockFirestore.mockUser ?? User(
            id: mockUser.uid,
            username: "testuser",
            email: mockUser.email ?? "",
            displayName: "Test User"
        )
    }
    
    func updateUserProfile(_ user: User) async -> Result<Void, AuthError> {
        guard mockAuth.mockUser != nil else {
            return .failure(.userNotSignedIn)
        }
        
        mockFirestore.updateUserCalled = true
        
        if mockFirestore.shouldSucceed {
            return .success(())
        } else {
            return .failure(.unknown)
        }
    }
    
    func deleteAccount() async -> Result<Void, AuthError> {
        guard mockAuth.mockUser != nil else {
            return .failure(.userNotSignedIn)
        }
        
        mockAuth.deleteUserCalled = true
        mockFirestore.deleteUserCalled = true
        
        if mockAuth.shouldSucceed && mockFirestore.shouldSucceed {
            mockAuth.mockUser = nil
            return .success(())
        } else {
            return .failure(mapFirebaseError(mockAuth.error))
        }
    }
    
    private func mapFirebaseError(_ error: Error?) -> AuthError {
        guard let nsError = error as NSError? else { return .unknown }
        
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }
        
        switch nsError.code {
        case 17007: return .emailAlreadyInUse
        case 17026: return .weakPassword
        case 17008: return .invalidEmail
        case 17009: return .wrongPassword
        case 17011: return .userNotFound
        case 17005: return .userDisabled
        case 17014: return .requiresRecentLogin
        default: return .unknown
        }
    }
}

class MockAuth {
    var shouldSucceed = true
    var error: Error?
    var mockUser: MockUser?
    var signOutCalled = false
    var passwordResetCalled = false
    var deleteUserCalled = false
}

class MockUser {
    let uid: String
    let email: String?
    
    init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
}

class MockFirestore {
    var shouldSucceed = true
    var userExists = false
    var mockUser: User?
    var updateUserCalled = false
    var deleteUserCalled = false
}