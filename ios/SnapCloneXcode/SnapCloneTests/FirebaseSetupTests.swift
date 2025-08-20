import XCTest
import SwiftUI
@testable import SnapClone

class FirebaseSetupTests: XCTestCase {
    
    func testFirebaseInitialization() throws {
        // ARRANGE
        let firebaseManager = FirebaseManager()
        
        // ACT & ASSERT
        XCTAssertTrue(firebaseManager.isConfigured, "Firebase should be configured")
        XCTAssertNotNil(firebaseManager.app, "Firebase app should not be nil")
    }
    
    func testFirebaseAuthAvailable() throws {
        // ARRANGE
        let firebaseManager = FirebaseManager()
        
        // ACT & ASSERT
        XCTAssertNotNil(firebaseManager.auth, "Firebase Auth should be available")
    }
    
    func testFirebaseFirestoreAvailable() throws {
        // ARRANGE
        let firebaseManager = FirebaseManager()
        
        // ACT & ASSERT
        XCTAssertNotNil(firebaseManager.firestore, "Firebase Firestore should be available")
    }
}