//
//  CameraService.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: AVFoundation camera service with full camera controls
//  Requirements: iOS 16+, AVFoundation
//

import Foundation
import AVFoundation
import UIKit
import Combine

/// Camera permission status
enum CameraPermissionStatus {
    case notDetermined
    case granted
    case denied
    case restricted
}

/// Camera position enumeration
enum CameraPosition {
    case front
    case back
    
    var avCaptureDevicePosition: AVCaptureDevice.Position {
        switch self {
        case .front: return .front
        case .back: return .back
        }
    }
}

/// Camera flash mode
enum CameraFlashMode {
    case off
    case on
    case auto
    
    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

/// Video quality settings
enum VideoQuality {
    case low
    case medium
    case high
    case ultra
    
    var avCaptureSessionPreset: AVCaptureSession.Preset {
        switch self {
        case .low: return .medium
        case .medium: return .high
        case .high: return .hd1280x720
        case .ultra: return .hd1920x1080
        }
    }
}

/// Custom camera errors
enum CameraError: LocalizedError {
    case permissionDenied
    case deviceNotAvailable
    case sessionConfigurationFailed
    case captureSessionNotRunning
    case recordingAlreadyInProgress
    case recordingNotInProgress
    case outputNotConfigured
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission is required to take photos and videos."
        case .deviceNotAvailable:
            return "Camera device is not available."
        case .sessionConfigurationFailed:
            return "Failed to configure camera session."
        case .captureSessionNotRunning:
            return "Camera session is not running."
        case .recordingAlreadyInProgress:
            return "Video recording is already in progress."
        case .recordingNotInProgress:
            return "No video recording in progress."
        case .outputNotConfigured:
            return "Camera output is not properly configured."
        case .unknown(let message):
            return message
        }
    }
}

/// Camera service for capturing photos and videos
@MainActor
final class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current camera permission status
    @Published var permissionStatus: CameraPermissionStatus = .notDetermined
    
    /// Whether camera session is running
    @Published var isSessionRunning = false
    
    /// Whether recording is in progress
    @Published var isRecording = false
    
    /// Current camera position
    @Published var currentPosition: CameraPosition = .back
    
    /// Current flash mode
    @Published var flashMode: CameraFlashMode = .off
    
    /// Current video quality
    @Published var videoQuality: VideoQuality = .high
    
    /// Current camera error
    @Published var cameraError: CameraError?
    
    /// Zoom factor (1.0 = no zoom)
    @Published var zoomFactor: CGFloat = 1.0
    
    /// Focus point (normalized coordinates)
    @Published var focusPoint: CGPoint?
    
    /// Exposure point (normalized coordinates)
    @Published var exposurePoint: CGPoint?
    
    // MARK: - Private Properties
    
    private let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var videoContinuation: CheckedContinuation<URL, Error>?
    
    // MARK: - Constants
    
    private struct Constants {
        static let maxZoomFactor: CGFloat = 10.0
        static let minZoomFactor: CGFloat = 1.0
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    deinit {
        stopSession()
    }
    
    // MARK: - Permission Management
    
    /// Check and update camera permission status
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionStatus = .granted
        case .notDetermined:
            permissionStatus = .notDetermined
        case .denied:
            permissionStatus = .denied
        case .restricted:
            permissionStatus = .restricted
        @unknown default:
            permissionStatus = .notDetermined
        }
    }
    
    /// Request camera permission
    /// - Returns: True if permission is granted
    func requestCameraPermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        
        await MainActor.run {
            self.permissionStatus = status ? .granted : .denied
        }
        
        return status
    }
    
    // MARK: - Session Management
    
    /// Setup and configure camera session
    /// - Throws: CameraError for setup failures
    func setupCamera() async throws {
        guard permissionStatus == .granted else {
            if await requestCameraPermission() {
                try await setupCamera()
                return
            } else {
                throw CameraError.permissionDenied
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.unknown("Service deallocated"))
                    return
                }
                
                do {
                    try self.configureSession()
                    
                    Task { @MainActor in
                        self.isSessionRunning = true
                    }
                    
                    continuation.resume()
                } catch {
                    let cameraError = error as? CameraError ?? CameraError.unknown(error.localizedDescription)
                    
                    Task { @MainActor in
                        self.cameraError = cameraError
                    }
                    
                    continuation.resume(throwing: cameraError)
                }
            }
        }
    }
    
    /// Configure capture session
    /// - Throws: CameraError for configuration failures
    private func configureSession() throws {
        captureSession.beginConfiguration()
        
        defer {
            captureSession.commitConfiguration()
        }
        
        // Set session preset
        captureSession.sessionPreset = videoQuality.avCaptureSessionPreset
        
        // Configure video input
        try configureVideoInput()
        
        // Configure photo output
        try configurePhotoOutput()
        
        // Configure movie output
        try configureMovieOutput()
    }
    
    /// Configure video input device
    /// - Throws: CameraError for input configuration failures
    private func configureVideoInput() throws {
        // Remove existing video input
        if let existingInput = videoDeviceInput {
            captureSession.removeInput(existingInput)
        }
        
        // Get camera device
        guard let videoDevice = getVideoDevice(for: currentPosition) else {
            throw CameraError.deviceNotAvailable
        }
        
        // Create device input
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                throw CameraError.sessionConfigurationFailed
            }
        } catch {
            throw CameraError.sessionConfigurationFailed
        }
    }
    
    /// Configure photo output
    /// - Throws: CameraError for output configuration failures
    private func configurePhotoOutput() throws {
        // Remove existing photo output
        if let existingOutput = photoOutput {
            captureSession.removeOutput(existingOutput)
        }
        
        let photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            self.photoOutput = photoOutput
            
            // Configure photo output settings
            photoOutput.isHighResolutionCaptureEnabled = true
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoOutput.isLivePhotoCaptureEnabled = false
            }
        } else {
            throw CameraError.sessionConfigurationFailed
        }
    }
    
    /// Configure movie file output
    /// - Throws: CameraError for output configuration failures
    private func configureMovieOutput() throws {
        // Remove existing movie output
        if let existingOutput = movieFileOutput {
            captureSession.removeOutput(existingOutput)
        }
        
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
            self.movieFileOutput = movieFileOutput
        } else {
            throw CameraError.sessionConfigurationFailed
        }
    }
    
    /// Start capture session
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                Task { @MainActor in
                    self.isSessionRunning = self.captureSession.isRunning
                }
            }
        }
    }
    
    /// Stop capture session
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                Task { @MainActor in
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    // MARK: - Device Management
    
    /// Get video device for position
    /// - Parameter position: Camera position
    /// - Returns: AVCaptureDevice or nil
    private func getVideoDevice(for position: CameraPosition) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInTelephotoCamera,
            .builtInUltraWideCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position.avCaptureDevicePosition
        )
        
        return discoverySession.devices.first
    }
    
    /// Switch camera position
    /// - Throws: CameraError for switching failures
    func switchCamera() async throws {
        let newPosition: CameraPosition = currentPosition == .back ? .front : .back
        
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.unknown("Service deallocated"))
                    return
                }
                
                self.captureSession.beginConfiguration()
                
                defer {
                    self.captureSession.commitConfiguration()
                }
                
                do {
                    // Remove current input
                    if let currentInput = self.videoDeviceInput {
                        self.captureSession.removeInput(currentInput)
                    }
                    
                    // Get new device
                    guard let newDevice = self.getVideoDevice(for: newPosition) else {
                        throw CameraError.deviceNotAvailable
                    }
                    
                    // Create new input
                    let newInput = try AVCaptureDeviceInput(device: newDevice)
                    
                    if self.captureSession.canAddInput(newInput) {
                        self.captureSession.addInput(newInput)
                        self.videoDeviceInput = newInput
                        
                        Task { @MainActor in
                            self.currentPosition = newPosition
                            self.zoomFactor = 1.0 // Reset zoom when switching cameras
                        }
                        
                        continuation.resume()
                    } else {
                        throw CameraError.sessionConfigurationFailed
                    }
                } catch {
                    let cameraError = error as? CameraError ?? CameraError.unknown(error.localizedDescription)
                    
                    Task { @MainActor in
                        self.cameraError = cameraError
                    }
                    
                    continuation.resume(throwing: cameraError)
                }
            }
        }
    }
    
    // MARK: - Photo Capture
    
    /// Capture a photo
    /// - Returns: Captured UIImage
    /// - Throws: CameraError for capture failures
    func capturePhoto() async throws -> UIImage {
        guard let photoOutput = photoOutput else {
            throw CameraError.outputNotConfigured
        }
        
        guard captureSession.isRunning else {
            throw CameraError.captureSessionNotRunning
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation
            
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.unknown("Service deallocated"))
                    return
                }
                
                // Configure photo settings
                let photoSettings = AVCapturePhotoSettings()
                
                // Set flash mode if supported
                if let device = self.videoDeviceInput?.device,
                   device.hasFlash && photoOutput.supportedFlashModes.contains(self.flashMode.avFlashMode) {
                    photoSettings.flashMode = self.flashMode.avFlashMode
                }
                
                // Set high resolution capture
                photoSettings.isHighResolutionPhotoEnabled = true
                
                // Capture photo
                photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
        }
    }
    
    // MARK: - Video Recording
    
    /// Start video recording
    /// - Returns: URL of recorded video file
    /// - Throws: CameraError for recording failures
    func startVideoRecording() async throws -> URL {
        guard let movieFileOutput = movieFileOutput else {
            throw CameraError.outputNotConfigured
        }
        
        guard captureSession.isRunning else {
            throw CameraError.captureSessionNotRunning
        }
        
        guard !isRecording else {
            throw CameraError.recordingAlreadyInProgress
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            videoContinuation = continuation
            
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.unknown("Service deallocated"))
                    return
                }
                
                // Create output file URL
                let outputFileName = "\(UUID().uuidString).mov"
                let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName)
                
                // Start recording
                movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
                
                Task { @MainActor in
                    self.isRecording = true
                }
            }
        }
    }
    
    /// Stop video recording
    /// - Throws: CameraError if recording is not in progress
    func stopVideoRecording() throws {
        guard let movieFileOutput = movieFileOutput else {
            throw CameraError.outputNotConfigured
        }
        
        guard isRecording else {
            throw CameraError.recordingNotInProgress
        }
        
        sessionQueue.async {
            movieFileOutput.stopRecording()
        }
    }
    
    // MARK: - Camera Controls
    
    /// Set zoom factor
    /// - Parameter zoomFactor: Desired zoom factor (1.0 - maxZoomFactor)
    func setZoom(_ zoomFactor: CGFloat) {
        let clampedZoom = max(Constants.minZoomFactor, min(zoomFactor, Constants.maxZoomFactor))
        
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let device = self.videoDeviceInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = min(clampedZoom, device.activeFormat.videoMaxZoomFactor)
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self.zoomFactor = device.videoZoomFactor
                }
            } catch {
                print("Error setting zoom: \(error)")
            }
        }
    }
    
    /// Set focus point
    /// - Parameter point: Focus point in normalized coordinates (0.0 - 1.0)
    func setFocus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let device = self.videoDeviceInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self.focusPoint = point
                }
            } catch {
                print("Error setting focus: \(error)")
            }
        }
    }
    
    /// Set exposure point
    /// - Parameter point: Exposure point in normalized coordinates (0.0 - 1.0)
    func setExposure(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let device = self.videoDeviceInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self.exposurePoint = point
                }
            } catch {
                print("Error setting exposure: \(error)")
            }
        }
    }
    
    /// Set flash mode
    /// - Parameter flashMode: Desired flash mode
    func setFlashMode(_ flashMode: CameraFlashMode) {
        self.flashMode = flashMode
    }
    
    /// Set video quality
    /// - Parameter quality: Desired video quality
    /// - Throws: CameraError for configuration failures
    func setVideoQuality(_ quality: VideoQuality) async throws {
        self.videoQuality = quality
        
        // Reconfigure session with new preset
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.unknown("Service deallocated"))
                    return
                }
                
                self.captureSession.beginConfiguration()
                
                if self.captureSession.canSetSessionPreset(quality.avCaptureSessionPreset) {
                    self.captureSession.sessionPreset = quality.avCaptureSessionPreset
                    self.captureSession.commitConfiguration()
                    continuation.resume()
                } else {
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.sessionConfigurationFailed)
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get preview layer for camera feed
    /// - Returns: AVCaptureVideoPreviewLayer
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    /// Check if flash is available
    /// - Returns: True if flash is available
    var isFlashAvailable: Bool {
        return videoDeviceInput?.device.hasFlash ?? false
    }
    
    /// Check if front camera is available
    /// - Returns: True if front camera is available
    var isFrontCameraAvailable: Bool {
        return getVideoDevice(for: .front) != nil
    }
    
    /// Check if back camera is available
    /// - Returns: True if back camera is available
    var isBackCameraAvailable: Bool {
        return getVideoDevice(for: .back) != nil
    }
    
    /// Get maximum zoom factor for current device
    /// - Returns: Maximum zoom factor
    var maxZoomFactor: CGFloat {
        guard let device = videoDeviceInput?.device else { return 1.0 }
        return min(device.activeFormat.videoMaxZoomFactor, Constants.maxZoomFactor)
    }
    
    /// Clear camera error
    func clearError() {
        cameraError = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            photoContinuation = nil
        }
        
        if let error = error {
            photoContinuation?.resume(throwing: CameraError.unknown(error.localizedDescription))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoContinuation?.resume(throwing: CameraError.unknown("Failed to create image from photo data"))
            return
        }
        
        photoContinuation?.resume(returning: image)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        Task { @MainActor in
            isRecording = true
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        defer {
            videoContinuation = nil
            Task { @MainActor in
                self.isRecording = false
            }
        }
        
        if let error = error {
            videoContinuation?.resume(throwing: CameraError.unknown(error.localizedDescription))
            return
        }
        
        videoContinuation?.resume(returning: outputFileURL)
    }
}