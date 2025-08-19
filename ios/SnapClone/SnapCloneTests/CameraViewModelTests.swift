//
//  CameraViewModelTests.swift
//  SnapCloneTests
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Comprehensive tests for Camera ViewModel photo capture and sharing logic
//

import XCTest
import AVFoundation
import Photos
@testable import SnapClone

@MainActor
final class CameraViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    var viewModel: CameraViewModel!
    var mockCameraService: MockCameraService!
    var mockPhotoService: MockPhotoService!
    var mockAuthService: MockAuthService!
    
    // MARK: - Test Lifecycle
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockCameraService = MockCameraService()
        mockPhotoService = MockPhotoService()
        mockAuthService = MockAuthService()
        
        viewModel = CameraViewModel(
            cameraService: mockCameraService,
            photoService: mockPhotoService,
            authService: mockAuthService
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockCameraService = nil
        mockPhotoService = nil
        mockAuthService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() throws {
        XCTAssertFalse(viewModel.isSessionRunning)
        XCTAssertFalse(viewModel.isCapturing)
        XCTAssertNil(viewModel.capturedPhoto)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.cameraPosition, .back)
        XCTAssertEqual(viewModel.flashMode, .off)
    }
    
    // MARK: - Camera Setup Tests
    
    func testStartCameraSessionSuccess() async throws {
        // Arrange
        mockCameraService.shouldSucceed = true
        mockCameraService.hasPermission = true
        
        // Act
        await viewModel.startCameraSession()
        
        // Assert
        XCTAssertTrue(viewModel.isSessionRunning)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(mockCameraService.startSessionCalled)
    }
    
    func testStartCameraSessionWithoutPermission() async throws {
        // Arrange
        mockCameraService.shouldSucceed = false
        mockCameraService.hasPermission = false
        
        // Act
        await viewModel.startCameraSession()
        
        // Assert
        XCTAssertFalse(viewModel.isSessionRunning)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("permission") ?? false)
    }
    
    func testStopCameraSession() async throws {
        // Arrange
        mockCameraService.shouldSucceed = true
        await viewModel.startCameraSession()
        
        // Act
        await viewModel.stopCameraSession()
        
        // Assert
        XCTAssertFalse(viewModel.isSessionRunning)
        XCTAssertTrue(mockCameraService.stopSessionCalled)
    }
    
    // MARK: - Photo Capture Tests
    
    func testCapturePhotoSuccess() async throws {
        // Arrange
        mockCameraService.shouldSucceed = true
        mockCameraService.hasPermission = true
        await viewModel.startCameraSession()
        
        let mockImageData = "mock_image_data".data(using: .utf8)!
        mockCameraService.mockCapturedImage = mockImageData
        
        // Act
        await viewModel.capturePhoto()
        
        // Assert
        XCTAssertNotNil(viewModel.capturedPhoto)
        XCTAssertFalse(viewModel.isCapturing)
        XCTAssertTrue(mockCameraService.capturePhotoCalled)
    }
    
    func testCapturePhotoFailure() async throws {
        // Arrange
        mockCameraService.shouldSucceed = false
        mockCameraService.hasPermission = true
        await viewModel.startCameraSession()
        
        mockCameraService.error = CameraError.captureFailure
        
        // Act
        await viewModel.capturePhoto()
        
        // Assert
        XCTAssertNil(viewModel.capturedPhoto)
        XCTAssertFalse(viewModel.isCapturing)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testCapturePhotoWhileCapturing() async throws {
        // Arrange
        mockCameraService.shouldSucceed = true
        mockCameraService.hasPermission = true
        await viewModel.startCameraSession()
        
        viewModel.isCapturing = true
        
        // Act
        await viewModel.capturePhoto()
        
        // Assert
        XCTAssertFalse(mockCameraService.capturePhotoCalled)
    }
    
    func testCapturePhotoWithoutSession() async throws {
        // Act
        await viewModel.capturePhoto()
        
        // Assert
        XCTAssertNil(viewModel.capturedPhoto)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(mockCameraService.capturePhotoCalled)
    }
    
    // MARK: - Camera Controls Tests
    
    func testSwitchCameraPosition() async throws {
        // Arrange
        mockCameraService.shouldSucceed = true
        await viewModel.startCameraSession()
        
        // Act
        await viewModel.switchCameraPosition()
        
        // Assert
        XCTAssertEqual(viewModel.cameraPosition, .front)
        XCTAssertTrue(mockCameraService.switchCameraCalled)
        
        // Switch back
        await viewModel.switchCameraPosition()
        XCTAssertEqual(viewModel.cameraPosition, .back)
    }
    
    func testSwitchCameraPositionFailure() async throws {
        // Arrange
        mockCameraService.shouldSucceed = false
        mockCameraService.error = CameraError.switchCameraFailure
        await viewModel.startCameraSession()
        
        // Act
        await viewModel.switchCameraPosition()
        
        // Assert
        XCTAssertEqual(viewModel.cameraPosition, .back) // Should remain unchanged
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testToggleFlashMode() throws {
        // Test cycling through flash modes
        XCTAssertEqual(viewModel.flashMode, .off)
        
        viewModel.toggleFlashMode()
        XCTAssertEqual(viewModel.flashMode, .on)
        
        viewModel.toggleFlashMode()
        XCTAssertEqual(viewModel.flashMode, .auto)
        
        viewModel.toggleFlashMode()
        XCTAssertEqual(viewModel.flashMode, .off)
    }
    
    func testZoomControls() throws {
        // Test zoom in
        viewModel.zoomIn()
        XCTAssertGreaterThan(viewModel.zoomLevel, 1.0)
        
        // Test zoom out
        let previousZoom = viewModel.zoomLevel
        viewModel.zoomOut()
        XCTAssertLessThan(viewModel.zoomLevel, previousZoom)
        
        // Test zoom limits
        viewModel.zoomLevel = 10.0
        viewModel.zoomIn()
        XCTAssertLessThanOrEqual(viewModel.zoomLevel, 10.0) // Should not exceed max
        
        viewModel.zoomLevel = 0.5
        viewModel.zoomOut()
        XCTAssertGreaterThanOrEqual(viewModel.zoomLevel, 1.0) // Should not go below min
    }
    
    // MARK: - Photo Sharing Tests
    
    func testSharePhotoWithFriends() async throws {
        // Arrange
        mockAuthService.currentUser = User(id: "user123", username: "testuser", email: "test@example.com", displayName: "Test User")
        mockPhotoService.shouldSucceed = true
        
        let mockImageData = "mock_image_data".data(using: .utf8)!
        viewModel.capturedPhoto = mockImageData
        
        let recipients = ["friend1", "friend2"]
        let caption = "Test photo"
        
        // Act
        await viewModel.sharePhoto(with: recipients, caption: caption)
        
        // Assert
        XCTAssertTrue(mockPhotoService.sharePhotoCalled)
        XCTAssertNil(viewModel.capturedPhoto) // Should clear after sharing
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSharePhotoFailure() async throws {
        // Arrange
        mockAuthService.currentUser = User(id: "user123", username: "testuser", email: "test@example.com", displayName: "Test User")
        mockPhotoService.shouldSucceed = false
        mockPhotoService.error = PhotoError.uploadFailure
        
        let mockImageData = "mock_image_data".data(using: .utf8)!
        viewModel.capturedPhoto = mockImageData
        
        // Act
        await viewModel.sharePhoto(with: ["friend1"], caption: "Test")
        
        // Assert
        XCTAssertNotNil(viewModel.capturedPhoto) // Should retain photo on failure
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testSharePhotoWithoutPhoto() async throws {
        // Act
        await viewModel.sharePhoto(with: ["friend1"], caption: "Test")
        
        // Assert
        XCTAssertFalse(mockPhotoService.sharePhotoCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testSharePhotoWithoutUser() async throws {
        // Arrange
        mockAuthService.currentUser = nil
        let mockImageData = "mock_image_data".data(using: .utf8)!
        viewModel.capturedPhoto = mockImageData
        
        // Act
        await viewModel.sharePhoto(with: ["friend1"], caption: "Test")
        
        // Assert
        XCTAssertFalse(mockPhotoService.sharePhotoCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Story Creation Tests
    
    func testCreateStory() async throws {
        // Arrange
        mockAuthService.currentUser = User(id: "user123", username: "testuser", email: "test@example.com", displayName: "Test User")
        mockPhotoService.shouldSucceed = true
        
        let mockImageData = "mock_image_data".data(using: .utf8)!
        viewModel.capturedPhoto = mockImageData
        
        // Act
        await viewModel.createStory(caption: "My story")
        
        // Assert
        XCTAssertTrue(mockPhotoService.createStoryCalled)
        XCTAssertNil(viewModel.capturedPhoto)
    }
    
    func testCreateStoryFailure() async throws {
        // Arrange
        mockAuthService.currentUser = User(id: "user123", username: "testuser", email: "test@example.com", displayName: "Test User")
        mockPhotoService.shouldSucceed = false
        mockPhotoService.error = PhotoError.uploadFailure
        
        let mockImageData = "mock_image_data".data(using: .utf8)!
        viewModel.capturedPhoto = mockImageData
        
        // Act
        await viewModel.createStory(caption: "My story")
        
        // Assert
        XCTAssertNotNil(viewModel.capturedPhoto)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Photo Library Tests
    
    func testSavePhotoToLibrary() async throws {
        // Arrange
        mockCameraService.hasPhotoLibraryPermission = true
        mockCameraService.shouldSucceed = true
        
        let mockImageData = "mock_image_data".data(using: .utf8)!
        viewModel.capturedPhoto = mockImageData
        
        // Act
        await viewModel.savePhotoToLibrary()
        
        // Assert
        XCTAssertTrue(mockCameraService.saveToLibraryCalled)
    }
    
    func testSavePhotoToLibraryWithoutPermission() async throws {
        // Arrange
        mockCameraService.hasPhotoLibraryPermission = false
        
        let mockImageData = "mock_image_data".data(using: .utf8)!
        viewModel.capturedPhoto = mockImageData
        
        // Act
        await viewModel.savePhotoToLibrary()
        
        // Assert
        XCTAssertFalse(mockCameraService.saveToLibraryCalled)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() throws {
        viewModel.errorMessage = "Test error"
        
        viewModel.clearError()
        
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testRetryFailedOperation() async throws {
        // Arrange
        mockCameraService.shouldSucceed = false
        mockCameraService.error = CameraError.sessionSetupFailure
        await viewModel.startCameraSession()
        
        XCTAssertNotNil(viewModel.errorMessage)
        
        // Act - retry with success
        mockCameraService.shouldSucceed = true
        await viewModel.retryLastOperation()
        
        // Assert
        XCTAssertTrue(viewModel.isSessionRunning)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Performance Tests
    
    func testPhotoCapturePerformance() throws {
        measure {
            Task {
                mockCameraService.shouldSucceed = true
                mockCameraService.hasPermission = true
                await viewModel.startCameraSession()
                await viewModel.capturePhoto()
            }
        }
    }
    
    func testCameraSwitchPerformance() throws {
        measure {
            Task {
                mockCameraService.shouldSucceed = true
                await viewModel.startCameraSession()
                await viewModel.switchCameraPosition()
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testViewModelMemoryManagement() throws {
        weak var weakViewModel: CameraViewModel?
        
        autoreleasepool {
            let tempViewModel = CameraViewModel(
                cameraService: MockCameraService(),
                photoService: MockPhotoService(),
                authService: MockAuthService()
            )
            weakViewModel = tempViewModel
        }
        
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
}

// MARK: - Mock Services

enum CameraError: Error {
    case noPermission
    case sessionSetupFailure
    case captureFailure
    case switchCameraFailure
}

enum PhotoError: Error {
    case uploadFailure
    case invalidData
    case storageError
}

class MockCameraService {
    var shouldSucceed = true
    var hasPermission = false
    var hasPhotoLibraryPermission = false
    var error: Error?
    var mockCapturedImage: Data?
    
    // Call tracking
    var startSessionCalled = false
    var stopSessionCalled = false
    var capturePhotoCalled = false
    var switchCameraCalled = false
    var saveToLibraryCalled = false
    
    func startSession() async throws {
        startSessionCalled = true
        guard shouldSucceed else { throw error ?? CameraError.sessionSetupFailure }
        guard hasPermission else { throw CameraError.noPermission }
    }
    
    func stopSession() async {
        stopSessionCalled = true
    }
    
    func capturePhoto() async throws -> Data {
        capturePhotoCalled = true
        guard shouldSucceed else { throw error ?? CameraError.captureFailure }
        return mockCapturedImage ?? Data()
    }
    
    func switchCamera() async throws {
        switchCameraCalled = true
        guard shouldSucceed else { throw error ?? CameraError.switchCameraFailure }
    }
    
    func saveToLibrary(_ imageData: Data) async throws {
        saveToLibraryCalled = true
        guard hasPhotoLibraryPermission else { throw CameraError.noPermission }
        guard shouldSucceed else { throw error ?? PhotoError.storageError }
    }
}

class MockPhotoService {
    var shouldSucceed = true
    var error: Error?
    
    var sharePhotoCalled = false
    var createStoryCalled = false
    
    func sharePhoto(_ imageData: Data, with recipients: [String], caption: String?) async throws {
        sharePhotoCalled = true
        guard shouldSucceed else { throw error ?? PhotoError.uploadFailure }
    }
    
    func createStory(_ imageData: Data, caption: String?) async throws {
        createStoryCalled = true
        guard shouldSucceed else { throw error ?? PhotoError.uploadFailure }
    }
}

class MockAuthService {
    var currentUser: User?
}

// MARK: - CameraViewModel Implementation

@MainActor
class CameraViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var isCapturing = false
    @Published var capturedPhoto: Data?
    @Published var errorMessage: String?
    @Published var cameraPosition: CameraPosition = .back
    @Published var flashMode: FlashMode = .off
    @Published var zoomLevel: CGFloat = 1.0
    
    // MARK: - Services
    private let cameraService: MockCameraService
    private let photoService: MockPhotoService
    private let authService: MockAuthService
    
    // MARK: - Private Properties
    private var lastFailedOperation: (() async -> Void)?
    
    init(cameraService: MockCameraService, photoService: MockPhotoService, authService: MockAuthService) {
        self.cameraService = cameraService
        self.photoService = photoService
        self.authService = authService
    }
    
    // MARK: - Camera Session Management
    
    func startCameraSession() async {
        do {
            try await cameraService.startSession()
            isSessionRunning = true
            errorMessage = nil
        } catch {
            isSessionRunning = false
            errorMessage = "Failed to start camera: \(error.localizedDescription)"
            lastFailedOperation = { await self.startCameraSession() }
        }
    }
    
    func stopCameraSession() async {
        await cameraService.stopSession()
        isSessionRunning = false
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() async {
        guard isSessionRunning else {
            errorMessage = "Camera session not running"
            return
        }
        
        guard !isCapturing else { return }
        
        isCapturing = true
        
        do {
            let imageData = try await cameraService.capturePhoto()
            capturedPhoto = imageData
            errorMessage = nil
        } catch {
            errorMessage = "Failed to capture photo: \(error.localizedDescription)"
        }
        
        isCapturing = false
    }
    
    // MARK: - Camera Controls
    
    func switchCameraPosition() async {
        do {
            try await cameraService.switchCamera()
            cameraPosition = cameraPosition == .back ? .front : .back
            errorMessage = nil
        } catch {
            errorMessage = "Failed to switch camera: \(error.localizedDescription)"
        }
    }
    
    func toggleFlashMode() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        }
    }
    
    func zoomIn() {
        zoomLevel = min(zoomLevel + 0.5, 10.0)
    }
    
    func zoomOut() {
        zoomLevel = max(zoomLevel - 0.5, 1.0)
    }
    
    // MARK: - Photo Sharing
    
    func sharePhoto(with recipients: [String], caption: String?) async {
        guard let photoData = capturedPhoto else {
            errorMessage = "No photo to share"
            return
        }
        
        guard authService.currentUser != nil else {
            errorMessage = "User not signed in"
            return
        }
        
        do {
            try await photoService.sharePhoto(photoData, with: recipients, caption: caption)
            capturedPhoto = nil
            errorMessage = nil
        } catch {
            errorMessage = "Failed to share photo: \(error.localizedDescription)"
        }
    }
    
    func createStory(caption: String?) async {
        guard let photoData = capturedPhoto else {
            errorMessage = "No photo to share"
            return
        }
        
        guard authService.currentUser != nil else {
            errorMessage = "User not signed in"
            return
        }
        
        do {
            try await photoService.createStory(photoData, caption: caption)
            capturedPhoto = nil
            errorMessage = nil
        } catch {
            errorMessage = "Failed to create story: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Photo Library
    
    func savePhotoToLibrary() async {
        guard let photoData = capturedPhoto else {
            errorMessage = "No photo to save"
            return
        }
        
        do {
            try await cameraService.saveToLibrary(photoData)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save photo: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    func retryLastOperation() async {
        await lastFailedOperation?()
    }
}

enum CameraPosition {
    case front
    case back
}

enum FlashMode {
    case off
    case on
    case auto
}