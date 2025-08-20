//
//  CameraPreviewView.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: AVFoundation camera preview wrapper for SwiftUI
//  Requirements: iOS 16+, AVFoundation, CameraViewModel integration
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraViewModel: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        // Setup camera preview layer if available
        if let previewLayer = cameraViewModel.previewLayer {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame on view changes
        if let previewLayer = cameraViewModel.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
        
        // Handle camera session state changes
        if cameraViewModel.isSessionRunning {
            // Ensure preview layer is properly configured
            setupPreviewLayerIfNeeded(in: uiView)
        }
    }
    
    private func setupPreviewLayerIfNeeded(in view: UIView) {
        guard let previewLayer = cameraViewModel.previewLayer else { return }
        
        // Check if preview layer is not already added
        if previewLayer.superlayer == nil {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
    }
}

#if DEBUG
#Preview {
    CameraPreviewView(cameraViewModel: CameraViewModel())
        .ignoresSafeArea()
}
#endif