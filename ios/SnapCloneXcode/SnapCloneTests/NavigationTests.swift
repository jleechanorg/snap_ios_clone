import XCTest
@testable import SnapClone

class NavigationTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Add UI test identifiers for debugging
        app.launchArguments.append("--UITest")
        app.launchEnvironment["UITEST_DEBUG"] = "1"
        
        print("🧪 [NavigationTests] Starting test setup...")
        let launchStart = CFAbsoluteTimeGetCurrent()
        app.launch()
        let launchTime = CFAbsoluteTimeGetCurrent() - launchStart
        print("⏱️ [NavigationTests] App launched in \(String(format: "%.3f", launchTime))s")
    }
    
    override func tearDown() {
        print("🧹 [NavigationTests] Cleaning up...")
        app.terminate()
        app = nil
        super.tearDown()
    }
    
    // ENHANCED TEST: Should navigate to main app after successful login
    func testNavigationAfterGoogleSignIn() {
        print("\n🧪 [NavigationTests] Testing Google Sign-In Navigation")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Given: User is on login screen
        XCTAssertTrue(app.staticTexts["SnapClone"].waitForExistence(timeout: 5), 
                     "SnapClone title should exist on login screen")
        print("✅ Login screen verified")
        
        // Capture before state
        let beforeScreenshot = app.screenshot()
        let beforeAttachment = XCTAttachment(screenshot: beforeScreenshot)
        beforeAttachment.name = "Before_Google_SignIn"
        beforeAttachment.lifetime = .keepAlways
        add(beforeAttachment)
        
        // When: User signs in with Google
        let signInButton = app.buttons["Sign In with Google"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 3), 
                     "Sign In with Google button should exist")
        XCTAssertTrue(signInButton.isHittable, 
                     "Sign In with Google button should be hittable")
        
        print("🔄 Tapping Sign In with Google button...")
        signInButton.tap()
        
        // Wait for navigation animation
        Thread.sleep(forTimeInterval: 1.0)
        
        // Then: Should navigate to main app interface
        let tabBar = app.tabBars.firstMatch
        let tabBarExists = tabBar.waitForExistence(timeout: 10)
        
        // Capture after state for debugging
        let afterScreenshot = app.screenshot()
        let afterAttachment = XCTAttachment(screenshot: afterScreenshot)
        afterAttachment.name = "After_Google_SignIn"
        afterAttachment.lifetime = .keepAlways
        add(afterAttachment)
        
        XCTAssertTrue(tabBarExists, "Should show tab bar after login within 10 seconds")
        
        if tabBarExists {
            XCTAssertTrue(app.buttons["Camera"].exists, "Should show Camera tab")
            XCTAssertTrue(app.buttons["Stories"].exists, "Should show Stories tab") 
            XCTAssertTrue(app.buttons["Chat"].exists, "Should show Chat tab")
            XCTAssertTrue(app.buttons["Profile"].exists, "Should show Profile tab")
            print("✅ All tabs verified successfully")
        } else {
            print("❌ Tab bar not found - navigation failed")
            
            // Debug information
            print("🔍 Debug: Checking current screen elements...")
            for element in app.debugDescription.components(separatedBy: "\n") {
                if element.contains("Button") || element.contains("Tab") {
                    print("  Found: \(element)")
                }
            }
        }
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Test completed in \(String(format: "%.3f", testDuration))s")
    }
    
    // ENHANCED TEST: Should be able to navigate between tabs
    func testTabNavigation() {
        print("\n🧪 [NavigationTests] Testing Tab Navigation")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Given: User is logged in and on main interface
        signInAndNavigateToMainApp()
        
        // When: User taps different tabs
        print("🔄 Testing Stories tab...")
        app.buttons["Stories"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Then: Should show Stories view
        let storiesExists = app.staticTexts["Stories"].waitForExistence(timeout: 3)
        if !storiesExists {
            print("⚠️ Stories content not found, checking if tab switched...")
            // Alternative check - verify we're not on camera anymore
            XCTAssertFalse(app.buttons["Capture"].exists, "Should not show camera capture on Stories tab")
        }
        
        print("🔄 Testing Chat tab...")
        app.buttons["Chat"].tap() 
        Thread.sleep(forTimeInterval: 0.5)
        
        // Then: Should show Chat view
        let chatExists = app.staticTexts["Messages"].waitForExistence(timeout: 3)
        if !chatExists {
            print("⚠️ Chat content not found, checking if tab switched...")
            XCTAssertFalse(app.buttons["Capture"].exists, "Should not show camera capture on Chat tab")
        }
        
        print("🔄 Testing Profile tab...")
        app.buttons["Profile"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Then: Should show Profile view
        let profileExists = app.staticTexts["Profile"].waitForExistence(timeout: 3)
        if !profileExists {
            print("⚠️ Profile content not found, checking for Sign Out button...")
            XCTAssertTrue(app.buttons["Sign Out"].waitForExistence(timeout: 3), "Should show Sign Out button on Profile")
        }
        
        print("🔄 Returning to Camera tab...")
        app.buttons["Camera"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Then: Should return to Camera view
        XCTAssertTrue(app.buttons["Capture"].waitForExistence(timeout: 3), "Should show camera capture button")
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Tab navigation test completed in \(String(format: "%.3f", testDuration))s")
    }
    
    // ENHANCED TEST: Should be able to sign out and return to login
    func testSignOutNavigation() {
        print("\n🧪 [NavigationTests] Testing Sign Out Navigation")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Given: User is logged in
        signInAndNavigateToMainApp()
        
        // When: User navigates to profile and signs out
        print("🔄 Navigating to Profile...")
        app.buttons["Profile"].tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5), "Sign Out button should exist")
        
        // Capture before sign out
        let beforeSignOut = app.screenshot()
        let beforeAttachment = XCTAttachment(screenshot: beforeSignOut)
        beforeAttachment.name = "Before_SignOut"
        beforeAttachment.lifetime = .keepAlways
        add(beforeAttachment)
        
        print("🔄 Tapping Sign Out...")
        signOutButton.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Then: Should return to login screen
        let snapCloneTitle = app.staticTexts["SnapClone"]
        let titleExists = snapCloneTitle.waitForExistence(timeout: 8)
        
        // Capture after sign out
        let afterSignOut = app.screenshot()
        let afterAttachment = XCTAttachment(screenshot: afterSignOut)
        afterAttachment.name = "After_SignOut"
        afterAttachment.lifetime = .keepAlways
        add(afterAttachment)
        
        XCTAssertTrue(titleExists, "Should return to login screen and show SnapClone title")
        XCTAssertTrue(app.buttons["Sign In with Google"].waitForExistence(timeout: 3), "Should show login buttons")
        
        // Verify tabs are gone
        XCTAssertFalse(app.tabBars.firstMatch.exists, "Tab bar should not exist after sign out")
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Sign out test completed in \(String(format: "%.3f", testDuration))s")
    }
    
    // ENHANCED TEST: Camera view should have functional elements
    func testCameraViewElements() {
        print("\n🧪 [NavigationTests] Testing Camera View Elements")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Given: User is on camera view
        signInAndNavigateToMainApp()
        print("🔄 Ensuring Camera tab is selected...")
        app.buttons["Camera"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Then: Should show camera controls
        let cameraElements = [
            ("Capture", "capture button"),
            ("FlipCamera", "flip camera button"), 
            ("Flash", "flash button")
        ]
        
        for (elementId, description) in cameraElements {
            let element = app.buttons[elementId]
            let exists = element.waitForExistence(timeout: 3)
            XCTAssertTrue(exists, "Should show \(description)")
            
            if exists {
                XCTAssertTrue(element.isHittable, "\(description) should be hittable")
                print("✅ \(description) verified")
            } else {
                print("❌ \(description) not found")
            }
        }
        
        // Capture camera view state
        let cameraScreenshot = app.screenshot()
        let cameraAttachment = XCTAttachment(screenshot: cameraScreenshot)
        cameraAttachment.name = "Camera_View_Elements"
        cameraAttachment.lifetime = .keepAlways
        add(cameraAttachment)
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Camera elements test completed in \(String(format: "%.3f", testDuration))s")
    }
    
    // Enhanced Helper method with better error handling
    private func signInAndNavigateToMainApp() {
        print("🔄 [Helper] Signing in and navigating to main app...")
        
        // Check if already signed in
        if app.tabBars.firstMatch.exists {
            print("✅ Already signed in")
            return
        }
        
        let signInButton = app.buttons["Sign In with Google"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign In button should exist")
        XCTAssertTrue(signInButton.isHittable, "Sign In button should be hittable")
        
        signInButton.tap()
        
        let tabBar = app.tabBars.firstMatch
        let success = tabBar.waitForExistence(timeout: 10)
        XCTAssertTrue(success, "Should navigate to main app with tab bar")
        
        if success {
            print("✅ Successfully navigated to main app")
        } else {
            print("❌ Failed to navigate to main app")
            
            // Debug output
            let debugScreenshot = app.screenshot()
            let debugAttachment = XCTAttachment(screenshot: debugScreenshot)
            debugAttachment.name = "SignIn_Failed_Debug"
            debugAttachment.lifetime = .keepAlways
            add(debugAttachment)
        }
    }
}