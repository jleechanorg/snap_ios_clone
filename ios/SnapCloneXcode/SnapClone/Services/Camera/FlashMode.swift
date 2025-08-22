//
//  FlashMode.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-20.
//  Purpose: Define flash mode enumeration for iOS Snapchat Clone
//  Requirements: AVFoundation integration, camera flash control
//

import Foundation
import AVFoundation
import SwiftUI

enum FlashMode: String, CaseIterable, Codable {
    case off = "off"
    case on = "on"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .on: return "On"
        case .auto: return "Auto"
        }
    }
    
    var shortName: String {
        switch self {
        case .off: return "Off"
        case .on: return "On"
        case .auto: return "Auto"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .off: return "bolt.slash"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .off: return .white.opacity(0.6)
        case .on: return .yellow
        case .auto: return .white
        }
    }
    
    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
    
    var avTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
    
    var next: FlashMode {
        switch self {
        case .off: return .on
        case .on: return .auto
        case .auto: return .off
        }
    }
    
    var isEnabled: Bool {
        return self != .off
    }
    
    // MARK: - Device Compatibility
    
    func isSupported(by device: AVCaptureDevice) -> Bool {
        switch self {
        case .off:
            return true
        case .on:
            return device.hasFlash
        case .auto:
            return device.hasFlash
        }
    }
    
    func canApply(to device: AVCaptureDevice) -> Bool {
        guard device.hasFlash else { return self == .off }
        
        switch self {
        case .off:
            return true
        case .on:
            return device.isFlashModeSupported(.on)
        case .auto:
            return device.isFlashModeSupported(.auto)
        }
    }
    
    // MARK: - Torch Support
    
    func supportsTorch(on device: AVCaptureDevice) -> Bool {
        guard device.hasTorch else { return false }
        
        switch self {
        case .off:
            return device.isTorchModeSupported(.off)
        case .on:
            return device.isTorchModeSupported(.on)
        case .auto:
            return device.isTorchModeSupported(.auto)
        }
    }
    
    // MARK: - UI Helpers
    
    var accessibilityLabel: String {
        switch self {
        case .off: return "Flash off"
        case .on: return "Flash on"
        case .auto: return "Auto flash"
        }
    }
    
    var helpText: String {
        switch self {
        case .off: return "Flash is disabled"
        case .on: return "Flash will fire for every photo"
        case .auto: return "Flash will fire automatically when needed"
        }
    }
}

// MARK: - Extensions

extension FlashMode {
    static var defaultMode: FlashMode {
        return .auto
    }
    
    static func supportedModes(for device: AVCaptureDevice) -> [FlashMode] {
        return FlashMode.allCases.filter { $0.isSupported(by: device) }
    }
    
    static func availableModes(for device: AVCaptureDevice) -> [FlashMode] {
        return FlashMode.allCases.filter { $0.canApply(to: device) }
    }
    
    static func from(avFlashMode: AVCaptureDevice.FlashMode) -> FlashMode {
        switch avFlashMode {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        @unknown default: return .off
        }
    }
    
    static func from(avTorchMode: AVCaptureDevice.TorchMode) -> FlashMode {
        switch avTorchMode {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        @unknown default: return .off
        }
    }
}

// MARK: - CustomStringConvertible

extension FlashMode: CustomStringConvertible {
    var description: String {
        return displayName
    }
}