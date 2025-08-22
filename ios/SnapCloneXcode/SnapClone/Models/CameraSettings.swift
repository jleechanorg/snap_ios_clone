//
//  CameraSettings.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-20.
//  Purpose: Camera configuration settings for iOS Snapchat Clone
//  Requirements: SwiftUI, Combine, Codable support
//

import Foundation
import SwiftUI

@objc(CameraSettings)
final class CameraSettings: NSObject, ObservableObject, Codable {
    @Published var isGridEnabled: Bool = false
    @Published var quality: PhotoQuality = .high
    @Published var includeLocation: Bool = false
    @Published var autoSaveToLibrary: Bool = true
    @Published var defaultViewDuration: TimeInterval = 10.0
    
    enum PhotoQuality: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"  
        case high = "high"
        
        var compressionQuality: CGFloat {
            switch self {
            case .low: return 0.3
            case .medium: return 0.7
            case .high: return 0.9
            }
        }
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
        
        var maxDimension: CGFloat {
            switch self {
            case .low: return 640
            case .medium: return 1080
            case .high: return 1920
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case isGridEnabled, quality, includeLocation, autoSaveToLibrary, defaultViewDuration
    }
    
    override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isGridEnabled = try container.decodeIfPresent(Bool.self, forKey: .isGridEnabled) ?? false
        quality = try container.decodeIfPresent(PhotoQuality.self, forKey: .quality) ?? .high
        includeLocation = try container.decodeIfPresent(Bool.self, forKey: .includeLocation) ?? false
        autoSaveToLibrary = try container.decodeIfPresent(Bool.self, forKey: .autoSaveToLibrary) ?? true
        defaultViewDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .defaultViewDuration) ?? 10.0
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isGridEnabled, forKey: .isGridEnabled)
        try container.encode(quality, forKey: .quality)
        try container.encode(includeLocation, forKey: .includeLocation)
        try container.encode(autoSaveToLibrary, forKey: .autoSaveToLibrary)
        try container.encode(defaultViewDuration, forKey: .defaultViewDuration)
    }
    
    // MARK: - Utility Methods
    
    func reset() {
        isGridEnabled = false
        quality = .high
        includeLocation = false
        autoSaveToLibrary = true
        defaultViewDuration = 10.0
    }
    
    func copy() -> CameraSettings {
        let settings = CameraSettings()
        settings.isGridEnabled = self.isGridEnabled
        settings.quality = self.quality
        settings.includeLocation = self.includeLocation
        settings.autoSaveToLibrary = self.autoSaveToLibrary
        settings.defaultViewDuration = self.defaultViewDuration
        return settings
    }
}

// MARK: - Extensions

extension CameraSettings {
    static var `default`: CameraSettings {
        return CameraSettings()
    }
    
    static var highQuality: CameraSettings {
        let settings = CameraSettings()
        settings.quality = .high
        settings.includeLocation = true
        return settings
    }
}