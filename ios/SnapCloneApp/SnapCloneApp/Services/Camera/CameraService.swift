import Foundation
import AVFoundation
import UIKit
import Combine

protocol CameraServiceDelegate: AnyObject {
    func cameraDidCapturePhoto(_ image: UIImage)
    func cameraDidFailWithError(_ error: CameraError)
    func cameraDidChangeAuthorizationStatus(_ status: AVAuthorizationStatus)
}

class CameraService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var isConfigured = false
    @Published var cameraPosition: CameraPosition = .back
    @Published var flashMode: FlashMode = .off
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    weak var delegate: CameraServiceDelegate?
    
    // MARK: - Initialization
    override init() {
        super.init()
        checkPermissions()
    }
    
    deinit {
        stopSession()
    }
    
    // MARK: - Permission Management
    private func checkPermissions() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .authorized:
            configureSession()
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            delegate?.cameraDidChangeAuthorizationStatus(authorizationStatus)
        @unknown default:
            delegate?.cameraDidFailWithError(.unknown)
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                if granted {
                    self?.configureSession()
                } else {
                    self?.delegate?.cameraDidChangeAuthorizationStatus(.denied)
                }
            }
        }
    }
    
    // MARK: - Session Configuration
    private func configureSession() {
        guard authorizationStatus == .authorized else { return }
        
        sessionQueue.async { [weak self] in
            self?.configureSessionInternal()
        }
    }
    
    private func configureSessionInternal() {
        guard !isConfigured else { return }
        
        session.beginConfiguration()
        
        // Configure session preset
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        // Add video input
        do {
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            guard let videoDevice = videoDevice else {
                DispatchQueue.main.async {
                    self.delegate?.cameraDidFailWithError(.deviceNotFound)
                }
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                DispatchQueue.main.async {
                    self.delegate?.cameraDidFailWithError(.cannotAddInput)
                }
                return
            }
        } catch {
            DispatchQueue.main.async {
                self.delegate?.cameraDidFailWithError(.cannotCreateInput)
            }
            return
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            DispatchQueue.main.async {
                self.delegate?.cameraDidFailWithError(.cannotAddOutput)
            }
            return
        }
        
        session.commitConfiguration()
        
        DispatchQueue.main.async {
            self.isConfigured = true
        }
    }
    
    // MARK: - Session Control
    func startSession() {
        guard isConfigured, authorizationStatus == .authorized else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
    
    // MARK: - Camera Controls
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let newPosition: AVCaptureDevice.Position = self.cameraPosition == .back ? .front : .back
            
            guard let newVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                DispatchQueue.main.async {
                    self.delegate?.cameraDidFailWithError(.deviceNotFound)
                }
                return
            }
            
            do {
                let newVideoDeviceInput = try AVCaptureDeviceInput(device: newVideoDevice)
                
                self.session.beginConfiguration()
                
                if let currentInput = self.videoDeviceInput {
                    self.session.removeInput(currentInput)
                }
                
                if self.session.canAddInput(newVideoDeviceInput) {
                    self.session.addInput(newVideoDeviceInput)
                    self.videoDeviceInput = newVideoDeviceInput
                    
                    DispatchQueue.main.async {
                        self.cameraPosition = newPosition == .back ? .back : .front
                    }
                } else {
                    // Re-add the original input if we can't add the new one
                    if let currentInput = self.videoDeviceInput {
                        self.session.addInput(currentInput)
                    }
                }
                
                self.session.commitConfiguration()
                
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.cameraDidFailWithError(.cannotCreateInput)
                }
            }
        }
    }
    
    func setFlashMode(_ mode: FlashMode) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let device = self.videoDeviceInput?.device,
                  device.hasFlash else { return }
            
            do {
                try device.lockForConfiguration()
                
                switch mode {
                case .off:
                    device.flashMode = .off
                case .on:
                    device.flashMode = .on
                case .auto:
                    device.flashMode = .auto
                }
                
                device.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.flashMode = mode
                }
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.cameraDidFailWithError(.configurationFailed)
                }
            }
        }
    }
    
    // MARK: - Photo Capture
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let photoSettings = AVCapturePhotoSettings()
            
            // Configure flash
            if self.videoDeviceInput?.device.hasFlash == true {
                switch self.flashMode {
                case .off:
                    photoSettings.flashMode = .off
                case .on:
                    photoSettings.flashMode = .on
                case .auto:
                    photoSettings.flashMode = .auto
                }
            }
            
            // Enable high resolution capture
            photoSettings.isHighResolutionPhotoEnabled = true
            
            // Set photo quality
            if let codec = photoSettings.availablePhotoCodecTypes.first {
                photoSettings.photoQualityPrioritization = .quality
            }
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // MARK: - Preview Layer
    func createPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.delegate?.cameraDidFailWithError(.captureFailed)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.delegate?.cameraDidFailWithError(.imageProcessingFailed)
            }
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.cameraDidCapturePhoto(image)
        }
    }
}

// MARK: - Error Types
enum CameraError: LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case cannotCreateInput
    case configurationFailed
    case captureFailed
    case imageProcessingFailed
    case permissionDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Camera device not found"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add photo output"
        case .cannotCreateInput:
            return "Cannot create camera input"
        case .configurationFailed:
            return "Camera configuration failed"
        case .captureFailed:
            return "Photo capture failed"
        case .imageProcessingFailed:
            return "Image processing failed"
        case .permissionDenied:
            return "Camera permission denied"
        case .unknown:
            return "Unknown camera error"
        }
    }
}