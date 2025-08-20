import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @State private var showingShareSheet = false
    @State private var showingPhotoPicker = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraViewModel.authorizationStatus == .authorized {
                if let capturedImage = cameraViewModel.capturedImage {
                    PhotoEditView(
                        image: capturedImage,
                        onSave: { editedImage in
                            cameraViewModel.capturedImage = editedImage
                            showingShareSheet = true
                        },
                        onRetake: {
                            cameraViewModel.retakePhoto()
                        }
                    )
                } else {
                    CameraPreviewView()
                }
            } else {
                CameraPermissionView()
            }
        }
        .onAppear {
            cameraViewModel.startSession()
        }
        .onDisappear {
            cameraViewModel.stopSession()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = cameraViewModel.capturedImage {
                SharePhotoView(image: image)
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                cameraViewModel.handleImageSelection(image)
            }
        }
        .alert("Camera Error", isPresented: $cameraViewModel.showError) {
            Button("OK") {
                cameraViewModel.dismissError()
            }
        } message: {
            Text(cameraViewModel.errorMessage ?? "")
        }
    }
}

struct CameraPreviewView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                CameraPreview(previewLayer: cameraViewModel.previewLayer)
                    .ignoresSafeArea()
                
                // Grid overlay
                if cameraViewModel.isGridVisible {
                    GridOverlay()
                }
                
                // Camera controls overlay
                VStack {
                    // Top controls
                    HStack {
                        Button(action: {
                            cameraViewModel.toggleFlash()
                        }) {
                            Image(systemName: flashIcon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            cameraViewModel.toggleGrid()
                        }) {
                            Image(systemName: "grid")
                                .font(.title2)
                                .foregroundColor(cameraViewModel.isGridVisible ? .yellow : .white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        Button(action: {
                            cameraViewModel.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack {
                        // Photo library button
                        Button(action: {
                            // Open photo picker
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        Spacer()
                        
                        // Capture button
                        Button(action: {
                            cameraViewModel.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 5)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                                    .scaleEffect(cameraViewModel.isCapturing ? 0.8 : 1.0)
                                    .animation(.easeInOut(duration: 0.1), value: cameraViewModel.isCapturing)
                            }
                        }
                        .disabled(cameraViewModel.isCapturing)
                        
                        Spacer()
                        
                        // Settings button
                        Button(action: {
                            // Open camera settings
                        }) {
                            Image(systemName: "gearshape")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    private var flashIcon: String {
        switch cameraViewModel.flashMode {
        case .off:
            return "bolt.slash"
        case .on:
            return "bolt"
        case .auto:
            return "bolt.badge.a"
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

struct GridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                path.move(to: CGPoint(x: width / 3, y: 0))
                path.addLine(to: CGPoint(x: width / 3, y: height))
                
                path.move(to: CGPoint(x: width * 2 / 3, y: 0))
                path.addLine(to: CGPoint(x: width * 2 / 3, y: height))
                
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: height / 3))
                path.addLine(to: CGPoint(x: width, y: height / 3))
                
                path.move(to: CGPoint(x: 0, y: height * 2 / 3))
                path.addLine(to: CGPoint(x: width, y: height * 2 / 3))
            }
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
        }
    }
}

struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("SnapClone needs access to your camera to take photos. Please enable camera access in Settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal)
            
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct PhotoEditView: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    let onRetake: () -> Void
    
    @State private var textOverlay = ""
    @State private var showingTextEditor = false
    @State private var selectedFilter: String?
    
    private let filters = ["Original", "Sepia", "Noir", "Vintage", "Vibrant"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Image preview
                    ZStack {
                        Image(uiImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: geometry.size.height * 0.7)
                        
                        // Text overlay
                        if !textOverlay.isEmpty {
                            Text(textOverlay)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2)
                        }
                    }
                    
                    Spacer()
                    
                    // Filter options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(filters, id: \.self) { filter in
                                Button(filter) {
                                    selectedFilter = filter == "Original" ? nil : filter
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == filter ? Color.yellow : Color.black.opacity(0.5))
                                )
                                .foregroundColor(selectedFilter == filter ? .black : .white)
                                .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    HStack(spacing: 40) {
                        Button(action: onRetake) {
                            VStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                Text("Retake")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            showingTextEditor = true
                        }) {
                            VStack {
                                Image(systemName: "textformat")
                                    .font(.title2)
                                Text("Text")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            onSave(processedImage)
                        }) {
                            VStack {
                                Image(systemName: "paperplane.fill")
                                    .font(.title2)
                                Text("Send")
                                    .font(.caption)
                            }
                            .foregroundColor(.yellow)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showingTextEditor) {
            TextEditorView(text: $textOverlay)
        }
    }
    
    private var processedImage: UIImage {
        var processedImage = image
        
        // Apply filter
        if let filterName = selectedFilter {
            // Apply filter based on selection
            switch filterName {
            case "Sepia":
                processedImage = applyFilter(to: processedImage, filterName: "CISepiaTone")
            case "Noir":
                processedImage = applyFilter(to: processedImage, filterName: "CIPhotoEffectNoir")
            case "Vintage":
                processedImage = applyFilter(to: processedImage, filterName: "CIPhotoEffectInstant")
            case "Vibrant":
                processedImage = applyFilter(to: processedImage, filterName: "CIVibrance")
            default:
                break
            }
        }
        
        // Add text overlay
        if !textOverlay.isEmpty {
            processedImage = addTextOverlay(to: processedImage, text: textOverlay)
        }
        
        return processedImage
    }
    
    private func applyFilter(to image: UIImage, filterName: String) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filter = CIFilter(name: filterName)
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else { return image }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return image }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func addTextOverlay(to image: UIImage, text: String) -> UIImage {
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
            x: (image.size.width - textSize.width) / 2,
            y: (image.size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: textAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}

struct TextEditorView: View {
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Add text...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Add Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(CameraViewModel())
        .environmentObject(FriendsViewModel())
}