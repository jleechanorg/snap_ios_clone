//
// SnapCloneNavigationTests.swift
// SnapCloneUITests
//
// Comprehensive UI automation test suite for SnapClone app navigation
// Generated with Claude Code and Cerebras for TDD Green phase
// Author: Claude Code Agent
// Purpose: Verify navigation flows and identify failing points
//

import XCTest
import Foundation

final class SnapCloneNavigationTests: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    private let defaultTimeout: TimeInterval = 10.0
    private let shortTimeout: TimeInterval = 5.0
    private let animationTimeout: TimeInterval = 2.0
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        // Initialize app with clean state
        app = XCUIApplication()
        app.launchArguments.append("--UITest")
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        
        print("🚀 Setting up SnapClone Navigation Tests")
        print("📱 Test Device: \(UIDevice.current.name)")
        print("🏗️ iOS Version: \(UIDevice.current.systemVersion)")
        
        let launchStart = CFAbsoluteTimeGetCurrent()
        app.launch()
        let launchTime = CFAbsoluteTimeGetCurrent() - launchStart
        print("⏱️ App launch completed in \(String(format: "%.3f", launchTime))s")
    }
    
    override func tearDown() {
        print("🧹 Cleaning up test environment")
        
        // Capture final screenshot for debugging
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Final_State_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Force terminate app
        app.terminate()
        app = nil
        
        super.tearDown()
        print("✅ Test cleanup completed")
    }
    
    // MARK: - Core Navigation Tests
    
    func testAppLaunchAndInitialState() {
        print("\n🧪 TEST: App Launch and Initial State Verification")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Verify app is running
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: defaultTimeout), 
                     "❌ App should reach foreground state within \(defaultTimeout)s")
        print("✅ App is running in foreground")
        
        // Take screenshot of initial state
        captureScreenshot(name: "Initial_Launch_State")
        
        // Verify login screen elements
        verifyLoginScreenElements()
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Test completed in \(String(format: "%.3f", testDuration))s")
        print("🎯 RESULT: App launch verification PASSED")
    }
    
    func testGoogleSignInNavigationFlow() {
        print("\n🧪 TEST: Google Sign-In Navigation Flow")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Verify initial login state
        verifyLoginScreenElements()
        
        // Perform Google Sign-In
        let signInSuccess = performGoogleSignIn()
        XCTAssertTrue(signInSuccess, "❌ Google Sign-In should complete successfully")
        
        // Verify navigation to main app
        let navigationSuccess = verifyMainAppNavigation()
        XCTAssertTrue(navigationSuccess, "❌ Should navigate to main app after sign-in")
        
        // Verify all tabs are present and functional
        verifyAllTabsPresent()
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Test completed in \(String(format: "%.3f", testDuration))s")
        print("🎯 RESULT: Google Sign-In navigation PASSED")
    }
    
    func testSnapchatSignInNavigationFlow() {
        print("\n🧪 TEST: Snapchat Sign-In Navigation Flow")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Verify initial login state
        verifyLoginScreenElements()
        
        // Perform Snapchat Sign-In
        let snapchatButton = app.buttons["Continue with Snapchat"]
        XCTAssertTrue(snapchatButton.waitForExistence(timeout: shortTimeout), 
                     "❌ Snapchat sign-in button should exist")
        XCTAssertTrue(snapchatButton.isHittable, "❌ Snapchat button should be hittable")
        
        print("🔄 Tapping Snapchat sign-in button...")
        snapchatButton.tap()
        
        // Verify navigation to main app
        let navigationSuccess = verifyMainAppNavigation()
        XCTAssertTrue(navigationSuccess, "❌ Should navigate to main app after Snapchat sign-in")
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Test completed in \(String(format: "%.3f", testDuration))s")
        print("🎯 RESULT: Snapchat Sign-In navigation PASSED")
    }
    
    func testComprehensiveTabNavigation() {
        print("\n🧪 TEST: Comprehensive Tab Navigation")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Login and get to main app
        loginToMainApp()
        
        // Test each tab individually
        testCameraTabNavigation()
        testStoriesTabNavigation()
        testChatTabNavigation()
        testProfileTabNavigation()
        
        // Test navigation cycle
        testTabNavigationCycle()
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Test completed in \(String(format: "%.3f", testDuration))s")
        print("🎯 RESULT: Comprehensive tab navigation PASSED")
    }
    
    func testSignOutAndReturnToLogin() {
        print("\n🧪 TEST: Sign Out and Return to Login")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Login and navigate to main app
        loginToMainApp()
        
        // Navigate to Profile tab
        let profileTab = app.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: shortTimeout), 
                     "❌ Profile tab should exist")
        
        print("🔄 Navigating to Profile tab...")
        profileTab.tap()
        
        // Wait for profile content to load
        Thread.sleep(forTimeInterval: animationTimeout)
        captureScreenshot(name: "Profile_Tab_Before_SignOut")
        
        // Find and tap Sign Out button
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: shortTimeout), 
                     "❌ Sign Out button should exist on Profile tab")
        XCTAssertTrue(signOutButton.isHittable, "❌ Sign Out button should be hittable")
        
        print("🔄 Tapping Sign Out button...")
        signOutButton.tap()
        
        // Wait for sign out animation
        Thread.sleep(forTimeInterval: animationTimeout)
        
        // Verify return to login screen
        let returnedToLogin = verifyReturnToLogin()
        XCTAssertTrue(returnedToLogin, "❌ Should return to login screen after sign out")
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Test completed in \(String(format: "%.3f", testDuration))s")
        print("🎯 RESULT: Sign out navigation PASSED")
    }
    
    func testCameraControlsInteraction() {
        print("\n🧪 TEST: Camera Controls Interaction")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Login and ensure we're on camera tab
        loginToMainApp()
        ensureCameraTabSelected()
        
        // Test camera control buttons
        let cameraControls = ["Capture", "FlipCamera", "Flash"]
        
        for control in cameraControls {
            let controlButton = app.buttons[control]
            XCTAssertTrue(controlButton.waitForExistence(timeout: shortTimeout), 
                         "❌ \(control) button should exist on Camera tab")
            XCTAssertTrue(controlButton.isHittable, "❌ \(control) button should be hittable")
            
            print("🔄 Testing \(control) button interaction...")
            controlButton.tap()
            
            // Verify button still exists after tap (indicating it's functional)
            XCTAssertTrue(controlButton.exists, "❌ \(control) button should still exist after tap")
            
            Thread.sleep(forTimeInterval: 0.5) // Brief pause between interactions
        }
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Test completed in \(String(format: "%.3f", testDuration))s")
        print("🎯 RESULT: Camera controls interaction PASSED")
    }
    
    func testNavigationPerformanceAndStability() {
        print("\n🧪 TEST: Navigation Performance and Stability")
        let testStart = CFAbsoluteTimeGetCurrent()
        
        // Login to main app
        loginToMainApp()
        
        // Perform rapid tab switching to test stability
        let tabs = ["Camera", "Stories", "Chat", "Profile", "Camera"]
        var navigationTimes: [TimeInterval] = []
        
        for (index, tab) in tabs.enumerated() {
            let navStart = CFAbsoluteTimeGetCurrent()
            
            let tabButton = app.buttons[tab]
            XCTAssertTrue(tabButton.waitForExistence(timeout: shortTimeout), 
                         "❌ \(tab) tab should exist (iteration \(index + 1))")
            
            tabButton.tap()
            
            // Wait for tab content to load
            Thread.sleep(forTimeInterval: 0.3)
            
            let navTime = CFAbsoluteTimeGetCurrent() - navStart
            navigationTimes.append(navTime)
            
            print("📊 \(tab) tab navigation: \(String(format: "%.3f", navTime))s")
        }
        
        // Calculate performance metrics
        let averageNavTime = navigationTimes.reduce(0, +) / Double(navigationTimes.count)
        let maxNavTime = navigationTimes.max() ?? 0
        
        print("📈 Average navigation time: \(String(format: "%.3f", averageNavTime))s")
        print("📈 Maximum navigation time: \(String(format: "%.3f", maxNavTime))s")
        
        // Performance assertions
        XCTAssertLessThan(averageNavTime, 2.0, "❌ Average navigation should be under 2 seconds")
        XCTAssertLessThan(maxNavTime, 3.0, "❌ Maximum navigation should be under 3 seconds")
        
        let testDuration = CFAbsoluteTimeGetCurrent() - testStart
        print("⏱️ Test completed in \(String(format: "%.3f", testDuration))s")
        print("🎯 RESULT: Performance and stability PASSED")
    }
    
    // MARK: - Individual Tab Tests
    
    private func testCameraTabNavigation() {
        print("📷 Testing Camera tab navigation...")
        
        let cameraTab = app.buttons["Camera"]
        XCTAssertTrue(cameraTab.waitForExistence(timeout: shortTimeout), 
                     "❌ Camera tab should exist")
        
        cameraTab.tap()
        Thread.sleep(forTimeInterval: animationTimeout)
        
        // Verify camera-specific elements
        let cameraElements = ["Capture", "FlipCamera", "Flash"]
        for element in cameraElements {
            XCTAssertTrue(app.buttons[element].waitForExistence(timeout: shortTimeout), 
                         "❌ \(element) should exist on Camera tab")
        }
        
        captureScreenshot(name: "Camera_Tab_Active")
        print("✅ Camera tab navigation verified")
    }
    
    private func testStoriesTabNavigation() {
        print("📚 Testing Stories tab navigation...")
        
        let storiesTab = app.buttons["Stories"]
        XCTAssertTrue(storiesTab.waitForExistence(timeout: shortTimeout), 
                     "❌ Stories tab should exist")
        
        storiesTab.tap()
        Thread.sleep(forTimeInterval: animationTimeout)
        
        // Verify we're no longer on camera tab
        XCTAssertFalse(app.buttons["Capture"].exists, 
                      "❌ Capture button should not exist on Stories tab")
        
        // Verify Stories tab is selected
        XCTAssertTrue(storiesTab.exists, "❌ Stories tab should still exist after selection")
        
        captureScreenshot(name: "Stories_Tab_Active")
        print("✅ Stories tab navigation verified")
    }
    
    private func testChatTabNavigation() {
        print("💬 Testing Chat tab navigation...")
        
        let chatTab = app.buttons["Chat"]
        XCTAssertTrue(chatTab.waitForExistence(timeout: shortTimeout), 
                     "❌ Chat tab should exist")
        
        chatTab.tap()
        Thread.sleep(forTimeInterval: animationTimeout)
        
        // Verify we're no longer on camera tab
        XCTAssertFalse(app.buttons["Capture"].exists, 
                      "❌ Capture button should not exist on Chat tab")
        
        // Verify Chat tab is selected
        XCTAssertTrue(chatTab.exists, "❌ Chat tab should still exist after selection")
        
        captureScreenshot(name: "Chat_Tab_Active")
        print("✅ Chat tab navigation verified")
    }
    
    private func testProfileTabNavigation() {
        print("👤 Testing Profile tab navigation...")
        
        let profileTab = app.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: shortTimeout), 
                     "❌ Profile tab should exist")
        
        profileTab.tap()
        Thread.sleep(forTimeInterval: animationTimeout)
        
        // Verify we're no longer on camera tab
        XCTAssertFalse(app.buttons["Capture"].exists, 
                      "❌ Capture button should not exist on Profile tab")
        
        // Verify profile-specific elements
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: shortTimeout), 
                     "❌ Sign Out button should exist on Profile tab")
        
        captureScreenshot(name: "Profile_Tab_Active")
        print("✅ Profile tab navigation verified")
    }
    
    private func testTabNavigationCycle() {
        print("🔄 Testing complete tab navigation cycle...")
        
        let tabs = ["Camera", "Stories", "Chat", "Profile", "Camera"]
        
        for tab in tabs {
            let tabButton = app.buttons[tab]
            XCTAssertTrue(tabButton.waitForExistence(timeout: shortTimeout), 
                         "❌ \(tab) tab should exist in cycle")
            
            tabButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            print("✅ Successfully navigated to \(tab) tab")
        }
        
        // Verify we're back on Camera tab
        XCTAssertTrue(app.buttons["Capture"].waitForExistence(timeout: shortTimeout), 
                     "❌ Should be back on Camera tab after full cycle")
        
        print("✅ Tab navigation cycle completed")
    }
    
    // MARK: - Helper Methods
    
    private func verifyLoginScreenElements() {
        print("🔍 Verifying login screen elements...")
        
        // Check for main login elements
        let snapCloneTitle = app.staticTexts["SnapClone"]
        XCTAssertTrue(snapCloneTitle.waitForExistence(timeout: shortTimeout), 
                     "❌ SnapClone title should exist on login screen")
        
        let googleSignInButton = app.buttons["Sign In with Google"]
        XCTAssertTrue(googleSignInButton.waitForExistence(timeout: shortTimeout), 
                     "❌ Google Sign-In button should exist")
        XCTAssertTrue(googleSignInButton.isHittable, 
                     "❌ Google Sign-In button should be hittable")
        
        let snapchatButton = app.buttons["Continue with Snapchat"]
        XCTAssertTrue(snapchatButton.waitForExistence(timeout: shortTimeout), 
                     "❌ Snapchat button should exist")
        XCTAssertTrue(snapchatButton.isHittable, 
                     "❌ Snapchat button should be hittable")
        
        print("✅ Login screen elements verified")
    }
    
    @discardableResult
    private func performGoogleSignIn() -> Bool {
        print("🔄 Performing Google Sign-In...")
        
        let googleSignInButton = app.buttons["Sign In with Google"]
        guard googleSignInButton.waitForExistence(timeout: shortTimeout) else {
            print("❌ Google Sign-In button not found")
            return false
        }
        
        guard googleSignInButton.isHittable else {
            print("❌ Google Sign-In button not hittable")
            return false
        }
        
        let tapStart = CFAbsoluteTimeGetCurrent()
        googleSignInButton.tap()
        let tapTime = CFAbsoluteTimeGetCurrent() - tapStart
        
        print("✅ Google Sign-In button tapped (response time: \(String(format: "%.3f", tapTime))s)")
        
        // Wait for sign-in animation
        Thread.sleep(forTimeInterval: animationTimeout)
        
        return true
    }
    
    @discardableResult
    private func verifyMainAppNavigation() -> Bool {
        print("🔍 Verifying navigation to main app...")
        
        // Check for tab bar existence
        let tabBar = app.tabBars.firstMatch
        if !tabBar.waitForExistence(timeout: defaultTimeout) {
            print("❌ Tab bar not found within \(defaultTimeout)s")
            captureScreenshot(name: "Navigation_Failed_No_TabBar")
            return false
        }
        
        print("✅ Tab bar found")
        
        // Verify all required tabs exist
        let requiredTabs = ["Camera", "Stories", "Chat", "Profile"]
        for tab in requiredTabs {
            let tabButton = app.buttons[tab]
            if !tabButton.waitForExistence(timeout: shortTimeout) {
                print("❌ \(tab) tab not found")
                captureScreenshot(name: "Navigation_Failed_Missing_\(tab)")
                return false
            }
            print("✅ \(tab) tab found")
        }
        
        captureScreenshot(name: "Main_App_Navigation_Success")
        print("✅ Main app navigation verified")
        return true
    }
    
    private func verifyAllTabsPresent() {
        print("🔍 Verifying all tabs are present and accessible...")
        
        let tabs = ["Camera", "Stories", "Chat", "Profile"]
        
        for tab in tabs {
            let tabButton = app.buttons[tab]
            XCTAssertTrue(tabButton.exists, "❌ \(tab) tab should exist")
            XCTAssertTrue(tabButton.isHittable, "❌ \(tab) tab should be hittable")
            print("✅ \(tab) tab verified")
        }
    }
    
    @discardableResult
    private func verifyReturnToLogin() -> Bool {
        print("🔍 Verifying return to login screen...")
        
        let googleSignInButton = app.buttons["Sign In with Google"]
        if !googleSignInButton.waitForExistence(timeout: defaultTimeout) {
            print("❌ Google Sign-In button not found after sign out")
            captureScreenshot(name: "SignOut_Failed_No_LoginButton")
            return false
        }
        
        if !googleSignInButton.isHittable {
            print("❌ Google Sign-In button not hittable after sign out")
            captureScreenshot(name: "SignOut_Failed_Button_Not_Hittable")
            return false
        }
        
        // Verify we're no longer on main app (no tabs should exist)
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            print("❌ Tab bar still exists after sign out")
            captureScreenshot(name: "SignOut_Failed_TabBar_Still_Exists")
            return false
        }
        
        captureScreenshot(name: "SignOut_Success_Back_To_Login")
        print("✅ Successfully returned to login screen")
        return true
    }
    
    private func loginToMainApp() {
        print("🔄 Logging in to main app...")
        
        // Check if already logged in
        if app.tabBars.firstMatch.exists {
            print("✅ Already logged in")
            return
        }
        
        // Perform login
        let signInSuccess = performGoogleSignIn()
        XCTAssertTrue(signInSuccess, "❌ Login should succeed")
        
        let navigationSuccess = verifyMainAppNavigation()
        XCTAssertTrue(navigationSuccess, "❌ Should navigate to main app")
        
        print("✅ Successfully logged in to main app")
    }
    
    private func ensureCameraTabSelected() {
        print("📷 Ensuring Camera tab is selected...")
        
        let cameraTab = app.buttons["Camera"]
        if cameraTab.exists {
            cameraTab.tap()
            Thread.sleep(forTimeInterval: animationTimeout)
        }
        
        // Verify camera elements are visible
        XCTAssertTrue(app.buttons["Capture"].waitForExistence(timeout: shortTimeout), 
                     "❌ Should be on Camera tab")
        
        print("✅ Camera tab is now selected")
    }
    
    private func captureScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(name)_\(Date().timeIntervalSince1970)"
        attachment.lifetime = .keepAlways
        add(attachment)
        print("📸 Screenshot captured: \(name)")
    }
}

// MARK: - Test Extensions

extension SnapCloneNavigationTests {
    
    /// Retry mechanism for flaky UI interactions
    private func retryAction(times: Int = 3, action: () throws -> Void) rethrows {
        var lastError: Error?
        
        for attempt in 1...times {
            do {
                try action()
                return
            } catch {
                lastError = error
                print("⚠️ Attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < times {
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
        }
        
        if let error = lastError {
            throw error
        }
    }
    
    /// Wait for element with custom timeout and retry logic
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0, retry: Bool = true) -> Bool {
        if element.waitForExistence(timeout: timeout) {
            return true
        }
        
        if retry {
            print("⚠️ Element not found, retrying...")
            Thread.sleep(forTimeInterval: 0.5)
            return element.waitForExistence(timeout: timeout / 2)
        }
        
        return false
    }
}