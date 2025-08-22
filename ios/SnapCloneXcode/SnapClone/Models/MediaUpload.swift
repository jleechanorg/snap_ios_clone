//
//  MediaUpload.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-20.
//  Purpose: Track media upload progress and state for iOS Snapchat Clone
//  Requirements: SwiftUI, Combine, Firebase Storage integration
//

import Foundation
import SwiftUI

@objc(MediaUpload)
final class MediaUpload: NSObject, Identifiable, ObservableObject {
    let id = UUID()
    let localURL: URL
    let mediaType: MediaType
    @Published var progress: Double = 0.0
    @Published var status: UploadStatus = .pending
    @Published var uploadedURL: String?
    @Published var errorMessage: String?
    @Published var thumbnailURL: String?
    let createdAt = Date()
    let fileSize: Int64
    
    enum UploadStatus: String, CaseIterable {
        case pending = "pending"
        case uploading = "uploading" 
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .uploading: return "Uploading"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .cancelled: return "Cancelled"
            }
        }
        
        var systemImageName: String {
            switch self {
            case .pending: return "clock"
            case .uploading: return "arrow.up.circle"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.triangle.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .uploading: return .blue
            case .completed: return .green
            case .failed: return .red
            case .cancelled: return .gray
            }
        }
    }
    
    enum MediaType: String, CaseIterable {
        case photo = "photo"
        case video = "video"
        
        var displayName: String {
            switch self {
            case .photo: return "Photo"
            case .video: return "Video"
            }
        }
        
        var systemImageName: String {
            switch self {
            case .photo: return "photo"
            case .video: return "video"
            }
        }
    }
    
    init(localURL: URL, mediaType: MediaType = .photo) {
        self.localURL = localURL
        self.mediaType = mediaType
        
        // Calculate file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
            self.fileSize = attributes[.size] as? Int64 ?? 0
        } catch {
            self.fileSize = 0
        }
        
        super.init()
    }
    
    // MARK: - Progress Management
    
    func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.progress = min(max(progress, 0.0), 1.0)
            if progress > 0 && self.status == .pending {
                self.status = .uploading
            }
        }
    }
    
    func complete(with url: String, thumbnailURL: String? = nil) {
        DispatchQueue.main.async {
            self.uploadedURL = url
            self.thumbnailURL = thumbnailURL
            self.progress = 1.0
            self.status = .completed
            self.errorMessage = nil
        }
    }
    
    func fail(with error: String) {
        DispatchQueue.main.async {
            self.errorMessage = error
            self.status = .failed
        }
    }
    
    func cancel() {
        DispatchQueue.main.async {
            self.status = .cancelled
        }
    }
    
    func retry() {
        DispatchQueue.main.async {
            self.status = .pending
            self.progress = 0.0
            self.errorMessage = nil
        }
    }
    
    // MARK: - Computed Properties
    
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var fileName: String {
        localURL.lastPathComponent
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var canRetry: Bool {
        status == .failed
    }
    
    var canCancel: Bool {
        status == .pending || status == .uploading
    }
    
    var progressPercentage: String {
        String(format: "%.0f%%", progress * 100)
    }
    
    var estimatedTimeRemaining: TimeInterval? {
        guard status == .uploading, progress > 0.0, progress < 1.0 else { return nil }
        
        let elapsed = Date().timeIntervalSince(createdAt)
        let totalEstimated = elapsed / progress
        return totalEstimated - elapsed
    }
    
    var estimatedTimeRemainingFormatted: String? {
        guard let remaining = estimatedTimeRemaining else { return nil }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: remaining)
    }
}

// MARK: - Extensions

extension MediaUpload {
    static func mockPhoto() -> MediaUpload {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mock_photo.jpg")
        return MediaUpload(localURL: tempURL, mediaType: .photo)
    }
    
    static func mockVideo() -> MediaUpload {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mock_video.mp4")
        return MediaUpload(localURL: tempURL, mediaType: .video)
    }
}