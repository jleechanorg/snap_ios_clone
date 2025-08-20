//
// CerebrasNavigationTests.swift
// SnapCloneTests
//
// 🚀🚀🚀 CEREBRAS GENERATED IN 804ms 🚀🚀🚀
// Comprehensive UI automation test suite for SnapClone app navigation
//

import XCTest

class CerebrasNavigationTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        app = nil
    }
    
    func testLoginToMainAppNavigation() {
        // Verify we start on LoginView
        let loginView = app.otherElements["LoginView"]
        XCTAssertTrue(loginView.exists, "LoginView should be visible on launch")
        
        // Tap Google Sign In button
        let googleSignInButton = app.buttons["Sign In with Google"]
        XCTAssertTrue(googleSignInButton.exists, "Google Sign In button should exist")
        googleSignInButton.tap()
        
        // Wait for authentication state change
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: app.otherElements["MainAppView"]
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, .completed, "MainAppView should appear after login")
        
        // Verify MainAppView with tabs is displayed
        let mainAppView = app.otherElements["MainAppView"]
        XCTAssertTrue(mainAppView.exists, "MainAppView should be visible after authentication")
        
        // Check tab bar exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist in MainAppView")
        
        // Verify expected tabs are present and test navigation
        let cameraTab = tabBar.buttons["Camera"]
        let storiesTab = tabBar.buttons["Stories"]
        let chatTab = tabBar.buttons["Chat"]
        let profileTab = tabBar.buttons["Profile"]
        
        XCTAssertTrue(cameraTab.exists, "Camera tab should exist")
        XCTAssertTrue(storiesTab.exists, "Stories tab should exist")
        XCTAssertTrue(chatTab.exists, "Chat tab should exist")
        XCTAssertTrue(profileTab.exists, "Profile tab should exist")
        
        // Test tab navigation
        storiesTab.tap()
        XCTAssertTrue(storiesTab.isSelected, "Stories tab should be selected after tap")
        
        chatTab.tap()
        XCTAssertTrue(chatTab.isSelected, "Chat tab should be selected after tap")
        
        profileTab.tap()
        XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected after tap")
        
        cameraTab.tap()
        XCTAssertTrue(cameraTab.isSelected, "Camera tab should be selected after tap")
    }
    
    func testLoginViewAccessibility() {
        // Debug: Print all elements on screen
        print("🔍 Login View Elements:")
        print(app.debugDescription)
        
        // Check sign in button exists and is accessible
        let signInButton = app.buttons["Sign In with Google"]
        XCTAssertTrue(signInButton.exists, "Sign in button should exist")
        XCTAssertTrue(signInButton.isHittable, "Sign in button should be hittable")
    }
    
    func testMainAppViewAccessibility() {
        // Pre-authentication state
        XCTAssertFalse(app.otherElements["MainAppView"].exists, "MainAppView should not exist initially")
        
        // Simulate login
        app.buttons["Sign In with Google"].tap()
        
        // Post-authentication state
        let mainAppExists = NSPredicate(format: "exists == true")
        let mainAppExpectation = XCTNSPredicateExpectation(
            predicate: mainAppExists,
            object: app.otherElements["MainAppView"]
        )
        
        let result = XCTWaiter.wait(for: [mainAppExpectation], timeout: 10.0)
        XCTAssertEqual(result, .completed, "MainAppView should become accessible after login")
        
        // Debug: Print main app elements
        print("🔍 Main App View Elements:")
        print(app.debugDescription)
        
        // Verify key components exist
        XCTAssertTrue(app.tabBars.firstMatch.exists, "Tab bar should be accessible")
        XCTAssertTrue(app.otherElements["MainAppView"].exists, "Main app view should be accessible")
    }
    
    func testSignOutFlow() {
        // Sign in first
        app.buttons["Sign In with Google"].tap()
        
        // Wait for main app
        let mainAppExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: app.otherElements["MainAppView"]
        )
        XCTWaiter.wait(for: [mainAppExpectation], timeout: 10.0)
        
        // Navigate to profile tab
        app.tabBars.firstMatch.buttons["Profile"].tap()
        
        // Tap sign out button
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.exists, "Sign out button should exist in profile")
        signOutButton.tap()
        
        // Verify we're back to login view
        let loginViewExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: app.buttons["Sign In with Google"]
        )
        let result = XCTWaiter.wait(for: [loginViewExpectation], timeout: 10.0)
        XCTAssertEqual(result, .completed, "Should return to login view after sign out")
    }
}