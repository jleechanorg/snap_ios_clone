import XCTest
@testable import SnapClone

class AuthenticationTests: XCTestCase {
    var authManager: AuthenticationManager!
    
    override func setUp() {
        super.setUp()
        authManager = AuthenticationManager()
        TestDataHelper.clearTestTokens()
    }
    
    override func tearDown() {
        TestDataHelper.clearTestTokens()
        authManager = nil
        super.tearDown()
    }
    
    func testGoogleSignInSuccess() {
        let expectation = XCTestExpectation(description: "Google Sign In Success")
        
        authManager.signInWithGoogle(token: "test_google_token") { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertEqual(user.username, TestDataHelper.testUsername)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Google Sign In failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSnapchatOAuthSuccess() {
        let expectation = XCTestExpectation(description: "Snapchat OAuth Success")
        
        authManager.signInWithSnapchat(token: TestDataHelper.testPassword) { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertEqual(user.username, TestDataHelper.testUsername)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Snapchat OAuth failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFirebaseAuthenticationSuccess() {
        let expectation = XCTestExpectation(description: "Firebase Auth Success")
        
        authManager.signInWithFirebase(email: TestDataHelper.testEmail, password: TestDataHelper.testPassword) { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertTrue(user.isAuthenticated)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Firebase authentication failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTokenStorageInKeychain() {
        let token = "test_auth_token_12345"
        let service = "SnapCloneAuth"
        let account = TestDataHelper.testUsername
        
        // Store token
        XCTAssertTrue(KeychainHelper.save(token, service: service, account: account))
        
        // Retrieve token
        let retrievedToken = KeychainHelper.load(service: service, account: account)
        XCTAssertEqual(retrievedToken, token)
        
        // Delete token
        XCTAssertTrue(KeychainHelper.delete(service: service, account: account))
    }
    
    func testSignOutFlow() {
        let expectation = XCTestExpectation(description: "Sign Out Success")
        
        // First sign in
        authManager.signInWithFirebase(email: TestDataHelper.testEmail, password: TestDataHelper.testPassword) { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertTrue(user.isAuthenticated)
                
                // Then sign out
                self.authManager.signOut { success in
                    XCTAssertTrue(success)
                    XCTAssertFalse(self.authManager.isAuthenticated)
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Authentication failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testReauthenticationFlow() {
        let expectation = XCTestExpectation(description: "Re-authentication Success")
        
        authManager.signInWithFirebase(email: TestDataHelper.testEmail, password: TestDataHelper.testPassword) { result in
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertTrue(user.isAuthenticated)
                
                // Sign out
                self.authManager.signOut { success in
                    XCTAssertTrue(success)
                    XCTAssertFalse(self.authManager.isAuthenticated)
                    
                    // Re-authenticate
                    self.authManager.signInWithFirebase(email: TestDataHelper.testEmail, password: TestDataHelper.testPassword) { result in
                        switch result {
                        case .success(let user):
                            XCTAssertNotNil(user)
                            XCTAssertTrue(user.isAuthenticated)
                            expectation.fulfill()
                        case .failure(let error):
                            XCTFail("Re-authentication failed with error: \(error)")
                        }
                    }
                }
            case .failure(let error):
                XCTFail("Initial authentication failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}