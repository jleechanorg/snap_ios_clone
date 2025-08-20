import Foundation
@testable import SnapClone

class TestDataHelper {
    static let testUsername = "jleechan"
    static let testPassword = "GWkgTArwBNHd"
    static let testEmail = "jleechan@example.com"
    
    static func setupTestUser() -> User {
        return User(
            id: "test_user_id",
            username: testUsername,
            email: testEmail,
            isAuthenticated: true
        )
    }
    
    static func setupMockTokens() {
        KeychainHelper.save("mock_google_token", service: "GoogleAuth", account: testUsername)
        KeychainHelper.save("mock_snapchat_token", service: "SnapchatAuth", account: testUsername)
        KeychainHelper.save("mock_firebase_token", service: "FirebaseAuth", account: testEmail)
    }
    
    static func clearTestTokens() {
        KeychainHelper.delete(service: "GoogleAuth", account: testUsername)
        KeychainHelper.delete(service: "SnapchatAuth", account: testUsername)
        KeychainHelper.delete(service: "FirebaseAuth", account: testEmail)
    }
}