//
//  CameraPosition.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-20.
//  Purpose: Define camera position enumeration for iOS Snapchat Clone
//  Requirements: AVFoundation integration, SwiftUI support
//

import Foundation
import AVFoundation

enum CameraPosition: String, CaseIterable, Codable {
    case front = "front"
    case back = "back"
    
    var displayName: String {
        switch self {
        case .front: return "Front Camera"
        case .back: return "Back Camera"
        }
    }
    
    var shortName: String {
        switch self {
        case .front: return "Front"
        case .back: return "Back"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .front: return "camera.rotate"
        case .back: return "camera"
        }
    }
    
    var avCaptureDevicePosition: AVCaptureDevice.Position {
        switch self {
        case .front: return .front
        case .back: return .back
        }
    }
    
    var opposite: CameraPosition {
        switch self {
        case .front: return .back
        case .back: return .front
        }
    }
    
    // MARK: - Device Capabilities
    
    var isAvailable: Bool {
        return AVCaptureDevice.default(for: .video) != nil ||
               getDevice() != nil
    }
    
    func getDevice() -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInUltraWideCamera,
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInTripleCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: avCaptureDevicePosition
        )
        
        return discoverySession.devices.first
    }
    
    var hasFlash: Bool {
        guard let device = getDevice() else { return false }
        return device.hasFlash
    }
    
    var hasTorch: Bool {
        guard let device = getDevice() else { return false }
        return device.hasTorch
    }
    
    var supportsZoom: Bool {
        guard let device = getDevice() else { return false }
        return device.maxAvailableVideoZoomFactor > 1.0
    }
    
    var maxZoomFactor: CGFloat {
        guard let device = getDevice() else { return 1.0 }
        return device.maxAvailableVideoZoomFactor
    }
    
    var minZoomFactor: CGFloat {
        guard let device = getDevice() else { return 1.0 }
        return device.minAvailableVideoZoomFactor
    }
    
    // MARK: - Focus and Exposure
    
    var supportsFocus: Bool {
        guard let device = getDevice() else { return false }
        return device.isFocusModeSupported(.autoFocus) ||
               device.isFocusModeSupported(.continuousAutoFocus)
    }
    
    var supportsExposure: Bool {
        guard let device = getDevice() else { return false }
        return device.isExposureModeSupported(.autoExpose) ||
               device.isExposureModeSupported(.continuousAutoExposure)
    }
    
    var supportsWhiteBalance: Bool {
        guard let device = getDevice() else { return false }
        return device.isWhiteBalanceModeSupported(.autoWhiteBalance) ||
               device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance)
    }
}

// MARK: - Extensions

extension CameraPosition {
    static var availablePositions: [CameraPosition] {
        return CameraPosition.allCases.filter { $0.isAvailable }
    }
    
    static var defaultPosition: CameraPosition {
        return .back
    }
    
    static func from(avPosition: AVCaptureDevice.Position) -> CameraPosition {
        switch avPosition {
        case .front: return .front
        case .back: return .back
        case .unspecified: return .back
        @unknown default: return .back
        }
    }
}

// MARK: - CustomStringConvertible

extension CameraPosition: CustomStringConvertible {
    var description: String {
        return displayName
    }
}