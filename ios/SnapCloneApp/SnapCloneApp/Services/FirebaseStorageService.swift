//
//  FirebaseStorageService.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Firebase Storage service for image/video upload with progress tracking
//  Requirements: iOS 16+, Firebase Storage SDK
//

import Foundation
import FirebaseStorage
import UIKit
import AVFoundation
import Combine

/// Custom storage errors
enum StorageError: LocalizedError {
    case invalidData
    case uploadFailed
    case downloadFailed
    case compressionFailed
    case userNotAuthenticated
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data provided for upload."
        case .uploadFailed:
            return "Failed to upload file to storage."
        case .downloadFailed:
            return "Failed to download file from storage."
        case .compressionFailed:
            return "Failed to compress media file."
        case .userNotAuthenticated:
            return "User must be authenticated to upload files."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .unknown(let message):
            return message
        }
    }
}

/// Upload progress information
struct UploadProgress {
    let bytesTransferred: Int64
    let totalBytes: Int64
    let progress: Double
    
    var isComplete: Bool {
        return progress >= 1.0
    }
    
    var formattedProgress: String {
        return String(format: "%.1f%%", progress * 100)
    }
}

/// Firebase Storage service for media upload and management
@MainActor
final class FirebaseStorageService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current upload progress
    @Published var uploadProgress: UploadProgress?
    
    /// Loading state for storage operations
    @Published var isUploading = false
    
    /// Current storage error
    @Published var storageError: StorageError?
    
    // MARK: - Private Properties
    
    private let storage = Storage.storage()
    private let authService = FirebaseAuthService.shared
    private var currentUploadTask: StorageUploadTask?
    
    // MARK: - Constants
    
    private struct Constants {
        static let imageCompressionQuality: CGFloat = 0.8
        static let maxImageSize: CGSize = CGSize(width: 1920, height: 1920)
        static let videoCompressionPreset = AVAssetExportPresetMediumQuality
    }
    
    // MARK: - Singleton
    
    static let shared = FirebaseStorageService()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Image Upload
    
    /// Upload an image to Firebase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - path: Storage path for the image
    ///   - compress: Whether to compress the image
    /// - Returns: Download URL of the uploaded image
    /// - Throws: StorageError for upload failures
    func uploadImage(_ image: UIImage, to path: String, compress: Bool = true) async throws -> String {
        guard authService.isAuthenticated else {
            throw StorageError.userNotAuthenticated
        }
        
        isUploading = true
        storageError = nil
        uploadProgress = nil
        
        defer {
            isUploading = false
            uploadProgress = nil
        }
        
        do {
            let imageData: Data
            
            if compress {
                imageData = try compressImage(image)
            } else {
                guard let data = image.jpegData(compressionQuality: 1.0) else {
                    throw StorageError.invalidData
                }
                imageData = data
            }
            
            let downloadURL = try await uploadData(imageData, to: path, contentType: "image/jpeg")
            
            print("Image uploaded successfully: \(downloadURL)")
            return downloadURL
        } catch {
            let storageError = error as? StorageError ?? StorageError.unknown(error.localizedDescription)
            self.storageError = storageError
            throw storageError
        }
    }
    
    /// Compress an image for upload
    /// - Parameter image: Image to compress
    /// - Returns: Compressed image data
    /// - Throws: StorageError if compression fails
    private func compressImage(_ image: UIImage) throws -> Data {
        let resizedImage = resizeImage(image, to: Constants.maxImageSize)
        
        guard let compressedData = resizedImage.jpegData(compressionQuality: Constants.imageCompressionQuality) else {
            throw StorageError.compressionFailed
        }
        
        return compressedData
    }
    
    /// Resize an image while maintaining aspect ratio
    /// - Parameters:
    ///   - image: Original image
    ///   - targetSize: Target size
    /// - Returns: Resized image
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        if scaleFactor >= 1.0 {
            return image
        }
        
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledImageSize)
        let scaledImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledImageSize))
        }
        
        return scaledImage
    }
    
    // MARK: - Video Upload
    
    /// Upload a video to Firebase Storage
    /// - Parameters:
    ///   - videoURL: Local URL of the video
    ///   - path: Storage path for the video
    ///   - compress: Whether to compress the video
    /// - Returns: Download URL of the uploaded video
    /// - Throws: StorageError for upload failures
    func uploadVideo(from videoURL: URL, to path: String, compress: Bool = true) async throws -> String {
        guard authService.isAuthenticated else {
            throw StorageError.userNotAuthenticated
        }
        
        isUploading = true
        storageError = nil
        uploadProgress = nil
        
        defer {
            isUploading = false
            uploadProgress = nil
        }
        
        do {
            let processedVideoURL: URL
            
            if compress {
                processedVideoURL = try await compressVideo(videoURL)
            } else {
                processedVideoURL = videoURL
            }
            
            let videoData = try Data(contentsOf: processedVideoURL)
            let downloadURL = try await uploadData(videoData, to: path, contentType: "video/mp4")
            
            // Clean up compressed video if it was created
            if compress && processedVideoURL != videoURL {
                try? FileManager.default.removeItem(at: processedVideoURL)
            }
            
            print("Video uploaded successfully: \(downloadURL)")
            return downloadURL
        } catch {
            let storageError = error as? StorageError ?? StorageError.unknown(error.localizedDescription)
            self.storageError = storageError
            throw storageError
        }
    }
    
    /// Compress a video for upload
    /// - Parameter videoURL: URL of the video to compress
    /// - Returns: URL of the compressed video
    /// - Throws: StorageError if compression fails
    private func compressVideo(_ videoURL: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let asset = AVAsset(url: videoURL)
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: Constants.videoCompressionPreset) else {
                continuation.resume(throwing: StorageError.compressionFailed)
                return
            }
            
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: outputURL)
                case .failed:
                    continuation.resume(throwing: StorageError.compressionFailed)
                case .cancelled:
                    continuation.resume(throwing: StorageError.compressionFailed)
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Generic Upload
    
    /// Upload data to Firebase Storage with progress tracking
    /// - Parameters:
    ///   - data: Data to upload
    ///   - path: Storage path
    ///   - contentType: MIME type of the content
    /// - Returns: Download URL of the uploaded file
    /// - Throws: StorageError for upload failures
    private func uploadData(_ data: Data, to path: String, contentType: String) async throws -> String {
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        
        return try await withCheckedThrowingContinuation { continuation in
            currentUploadTask = storageRef.putData(data, metadata: metadata) { [weak self] metadata, error in
                if let error = error {
                    continuation.resume(throwing: StorageError.uploadFailed)
                    return
                }
                
                // Get download URL
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: StorageError.downloadFailed)
                        return
                    }
                    
                    guard let downloadURL = url?.absoluteString else {
                        continuation.resume(throwing: StorageError.downloadFailed)
                        return
                    }
                    
                    continuation.resume(returning: downloadURL)
                }
            }
            
            // Monitor upload progress
            currentUploadTask?.observe(.progress) { [weak self] snapshot in
                guard let progress = snapshot.progress else { return }
                
                let uploadProgress = UploadProgress(
                    bytesTransferred: progress.completedUnitCount,
                    totalBytes: progress.totalUnitCount,
                    progress: progress.fractionCompleted
                )
                
                Task { @MainActor in
                    self?.uploadProgress = uploadProgress
                }
            }
        }
    }
    
    // MARK: - File Management
    
    /// Delete a file from Firebase Storage
    /// - Parameter path: Storage path of the file to delete
    /// - Throws: StorageError for deletion failures
    func deleteMedia(at path: String) async throws {
        guard authService.isAuthenticated else {
            throw StorageError.userNotAuthenticated
        }
        
        do {
            let storageRef = storage.reference().child(path)
            try await storageRef.delete()
            
            print("File deleted successfully: \(path)")
        } catch {
            let storageError = StorageError.unknown(error.localizedDescription)
            self.storageError = storageError
            throw storageError
        }
    }
    
    /// Get download URL for a file
    /// - Parameter path: Storage path of the file
    /// - Returns: Download URL
    /// - Throws: StorageError for download failures
    func getDownloadURL(for path: String) async throws -> String {
        do {
            let storageRef = storage.reference().child(path)
            let url = try await storageRef.downloadURL()
            return url.absoluteString
        } catch {
            let storageError = StorageError.downloadFailed
            self.storageError = storageError
            throw storageError
        }
    }
    
    /// Cancel current upload
    func cancelUpload() {
        currentUploadTask?.cancel()
        currentUploadTask = nil
        isUploading = false
        uploadProgress = nil
    }
    
    // MARK: - Utility Methods
    
    /// Generate storage path for user content
    /// - Parameters:
    ///   - userId: User ID
    ///   - contentType: Type of content (images, videos, etc.)
    ///   - filename: Optional filename (UUID will be generated if nil)
    /// - Returns: Storage path
    func generateStoragePath(for userId: String, contentType: String, filename: String? = nil) -> String {
        let fileName = filename ?? "\(UUID().uuidString)"
        return "users/\(userId)/\(contentType)/\(fileName)"
    }
    
    /// Generate storage path for profile images
    /// - Parameter userId: User ID
    /// - Returns: Storage path for profile image
    func generateProfileImagePath(for userId: String) -> String {
        return generateStoragePath(for: userId, contentType: "profile", filename: "profile.jpg")
    }
    
    /// Generate storage path for snaps
    /// - Parameter userId: User ID
    /// - Returns: Storage path for snap
    func generateSnapPath(for userId: String) -> String {
        return generateStoragePath(for: userId, contentType: "snaps")
    }
    
    /// Generate storage path for stories
    /// - Parameter userId: User ID
    /// - Returns: Storage path for story
    func generateStoryPath(for userId: String) -> String {
        return generateStoragePath(for: userId, contentType: "stories")
    }
    
    /// Clear storage error
    func clearError() {
        storageError = nil
    }
    
    /// Get file size from storage
    /// - Parameter path: Storage path
    /// - Returns: File size in bytes
    /// - Throws: StorageError for metadata retrieval failures
    func getFileSize(at path: String) async throws -> Int64 {
        do {
            let storageRef = storage.reference().child(path)
            let metadata = try await storageRef.getMetadata()
            return metadata.size
        } catch {
            throw StorageError.unknown(error.localizedDescription)
        }
    }
}

// MARK: - FirebaseStorageService Extensions

extension FirebaseStorageService {
    /// Upload progress as AsyncStream
    /// - Returns: AsyncStream of upload progress updates
    func uploadProgressStream() -> AsyncStream<UploadProgress?> {
        AsyncStream { continuation in
            let cancellable = $uploadProgress.sink { progress in
                continuation.yield(progress)
            }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    /// Check if a file exists in storage
    /// - Parameter path: Storage path to check
    /// - Returns: True if file exists
    func fileExists(at path: String) async -> Bool {
        do {
            let storageRef = storage.reference().child(path)
            _ = try await storageRef.getMetadata()
            return true
        } catch {
            return false
        }
    }
}