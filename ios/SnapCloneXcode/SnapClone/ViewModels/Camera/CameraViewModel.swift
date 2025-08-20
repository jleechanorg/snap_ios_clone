import Foundation
import SwiftUI
import AVFoundation
import Photos
import Combine
import Firebase
import FirebaseStorage

@MainActor
class CameraViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var isConfigured = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var cameraPosition: CameraPosition = .back
    @Published var flashMode: FlashMode = .off
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    @Published var showImagePicker = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Camera settings
    @Published var settings = CameraSettings()
    @Published var isGridVisible = false
    @Published var zoomLevel: CGFloat = 1.0
    
    // Media uploads
    @Published var activeUploads: [MediaUpload] = []
    @Published var isUploading = false
    
    // Preview
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Dependencies
    private let cameraService = CameraService()
    private let messagingService: MessagingServiceProtocol = FirebaseMessagingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupCameraService()
        requestPhotoLibraryPermission()
    }
    
    // MARK: - Camera Setup
    
    func setupCamera() {
        cameraService.delegate = self
        
        // Bind published properties
        cameraService.$isSessionRunning
            .assign(to: &$isSessionRunning)
        
        cameraService.$isConfigured
            .assign(to: &$isConfigured)
        
        cameraService.$authorizationStatus
            .assign(to: &$authorizationStatus)
        
        cameraService.$cameraPosition
            .assign(to: &$cameraPosition)
        
        cameraService.$flashMode
            .assign(to: &$flashMode)
        
        // Create preview layer
        previewLayer = cameraService.createPreviewLayer()
    }
    
    private func setupCameraService() {
        // This will trigger permission request and setup
        setupCamera()
    }
    
    // MARK: - Camera Controls
    
    func startSession() {
        cameraService.startSession()
    }
    
    func stopSession() {
        cameraService.stopSession()
    }
    
    func capturePhoto() {
        guard !isCapturing else { return }
        
        isCapturing = true
        cameraService.capturePhoto()
    }
    
    func switchCamera() {
        cameraService.switchCamera()
    }
    
    func toggleFlash() {
        let newMode: FlashMode
        switch flashMode {
        case .off:
            newMode = .on
        case .on:
            newMode = .auto
        case .auto:
            newMode = .off
        }
        
        cameraService.setFlashMode(newMode)
    }
    
    func toggleGrid() {
        isGridVisible.toggle()
        settings.isGridEnabled = isGridVisible
    }
    
    func setZoom(_ level: CGFloat) {
        zoomLevel = max(1.0, min(5.0, level))
        // Implementation would set zoom on camera device
    }
    
    // MARK: - Photo Library
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status != .authorized {
                    self?.showErrorMessage("Photo library access required to save photos")
                }
            }
        }
    }
    
    func savePhotoToLibrary(_ image: UIImage) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            showErrorMessage("Photo library access required")
            return
        }
        
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Photo saved successfully
                } else if let error = error {
                    self?.showErrorMessage("Failed to save photo: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Photo Sharing
    
    func sharePhoto(_ image: UIImage, to userId: String, caption: String? = nil) async {
        do {
            // Create temporary file URL
            let tempURL = createTempImageURL(image)
            
            // Create upload tracking
            var upload = MediaUpload(localURL: tempURL)
            activeUploads.append(upload)
            isUploading = true
            
            // Upload image to Firebase Storage
            let uploadedURL = try await uploadImageToStorage(image, progress: { progress in
                DispatchQueue.main.async {
                    if let index = self.activeUploads.firstIndex(where: { $0.id == upload.id }) {
                        self.activeUploads[index].updateProgress(progress)
                    }
                }
            })
            
            // Create message
            guard let currentUserId = FirebaseAuthService.shared.getCurrentUser()?.uid else {
                throw CameraError.userNotAuthenticated
            }
            
            let conversationId = Conversation.generateId(for: [currentUserId, userId])
            let message = Message(
                senderId: currentUserId,
                receiverId: userId,
                conversationId: conversationId,
                content: caption,
                mediaURL: uploadedURL,
                messageType: .image,
                isEphemeral: true,
                viewDuration: 10.0
            )
            
            // Send message
            try await messagingService.sendMessage(message)
            
            // Update upload status
            DispatchQueue.main.async {
                if let index = self.activeUploads.firstIndex(where: { $0.id == upload.id }) {
                    self.activeUploads[index].complete(with: uploadedURL)
                }
                self.isUploading = false
                self.capturedImage = nil
            }
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            DispatchQueue.main.async {
                if let index = self.activeUploads.firstIndex(where: { $0.id == upload.id }) {
                    self.activeUploads[index].fail(with: error.localizedDescription)
                }
                self.isUploading = false
                self.showErrorMessage("Failed to share photo: \(error.localizedDescription)")
            }
        }
    }
    
    private func uploadImageToStorage(_ image: UIImage, progress: @escaping (Double) -> Void) async throws -> String {
        // Convert image to data
        guard let imageData = image.jpegData(compressionQuality: settings.quality.compressionQuality) else {
            throw CameraError.imageProcessingFailed
        }
        
        // Create storage reference
        let fileName = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("images/\(fileName)")
        
        // Upload with progress tracking
        let uploadTask = storageRef.putData(imageData)
        
        // Monitor progress
        uploadTask.observe(.progress) { snapshot in
            guard let progressValue = snapshot.progress else { return }
            let percentComplete = Double(progressValue.completedUnitCount) / Double(progressValue.totalUnitCount)
            progress(percentComplete)
        }
        
        // Wait for completion
        _ = try await uploadTask
        
        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    private func createTempImageURL(_ image: UIImage) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: fileURL)
        }
        
        return fileURL
    }
    
    // MARK: - Image Editing
    
    func addTextOverlay(to image: UIImage, text: String, position: CGPoint = CGPoint(x: 0.5, y: 0.5)) -> UIImage {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -2.0
        ]
        
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: .zero)
        
        let textSize = text.size(withAttributes: textAttributes)
        let textRect = CGRect(
            x: (image.size.width * position.x) - (textSize.width / 2),
            y: (image.size.height * position.y) - (textSize.height / 2),
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: textAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    func applyFilter(to image: UIImage, filterName: String = "CISepiaTone") -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filter = CIFilter(name: filterName)
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else { return image }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return image }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Error Handling
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func dismissError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - UI Actions
    
    func retakePhoto() {
        capturedImage = nil
    }
    
    func openImagePicker() {
        showImagePicker = true
    }
    
    func handleImageSelection(_ image: UIImage) {
        capturedImage = image
        showImagePicker = false
    }
}

// MARK: - CameraServiceDelegate
extension CameraViewModel: CameraServiceDelegate {
    func cameraDidCapturePhoto(_ image: UIImage) {
        capturedImage = image
        isCapturing = false
        
        // Optionally save to photo library
        savePhotoToLibrary(image)
    }
    
    func cameraDidFailWithError(_ error: CameraError) {
        isCapturing = false
        showErrorMessage(error.localizedDescription)
    }
    
    func cameraDidChangeAuthorizationStatus(_ status: AVAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .denied, .restricted:
            showErrorMessage("Camera access is required to take photos")
        default:
            break
        }
    }
}

// MARK: - Additional Error Types
extension CameraViewModel {
    enum CameraError: LocalizedError {
        case userNotAuthenticated
        case imageProcessingFailed
        case uploadFailed
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .userNotAuthenticated:
                return "User not authenticated"
            case .imageProcessingFailed:
                return "Failed to process image"
            case .uploadFailed:
                return "Failed to upload image"
            case .unknown:
                return "An unknown error occurred"
            }
        }
    }
}