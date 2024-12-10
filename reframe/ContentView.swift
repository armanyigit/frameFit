import SwiftUI
import PhotosUI
import Photos

#if os(iOS)
extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
#endif

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                    windowScene.requestGeometryUpdate(geometryPreferences)
                }
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct ContentView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var imageDataArray: [Data] = []
    @State private var previewImages: [UIImage] = []
    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var saveMessage: String? = nil
    @State private var selectedAspectRatio: AspectRatio? = nil
    @State private var selectedImageIndex: Int = 0
    @State private var processingProgress: String = ""
    @State private var warningMessage: String? = nil
    
    let aspectRatios: [AspectRatio] = [
        AspectRatio(name: "Square", ratio: 1, maxWidth: 1080, maxHeight: 1080),
        AspectRatio(name: "Portrait", ratio: 4/5, maxWidth: 1080, maxHeight: 1350),
        AspectRatio(name: "Landscape", ratio: 16/9, maxWidth: 1080, maxHeight: 608)
    ]
    
    init() {
        _selectedAspectRatio = State(initialValue: aspectRatios[1]) // Portrait as default
        
        // Force portrait orientation
        if !UIDevice.isIPad {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                windowScene.requestGeometryUpdate(geometryPreferences)
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if !previewImages.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(aspectRatios, id: \.self) { ratio in
                            VStack(spacing: 4) {
                                Image(systemName: ratio.name == "Square" ? "square.fill" : 
                                                ratio.name == "Portrait" ? "rectangle.portrait.fill" : 
                                                "rectangle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedAspectRatio == ratio ? .blue : .gray)
                                
                                Text(ratio.name)
                                    .font(.caption)
                                    .foregroundColor(selectedAspectRatio == ratio ? .blue : .gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedAspectRatio == ratio ? Color.blue.opacity(0.1) : Color.clear)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedAspectRatio = ratio
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .disabled(isLoading || isSaving)
                    .onChange(of: selectedAspectRatio) { oldValue, newValue in
                        // Only process if the aspect ratio actually changed
                        guard !imageDataArray.isEmpty && oldValue != newValue else { return }
                        isLoading = true
                        processAndPreviewImages()
                    }
                    
                    Spacer().frame(height: 16)
                }
                
                // Image viewer and loading overlay
                ZStack {
                    if !imageDataArray.isEmpty {
                        GeometryReader { geometry in
                            let imageHeight = selectedAspectRatio?.ratio != nil ? UIScreen.main.bounds.width / selectedAspectRatio!.ratio : 0
                            
                            ZStack(alignment: .center) {
                                // Image viewer
                                TabView(selection: $selectedImageIndex) {
                                    ForEach(previewImages.indices, id: \.self) { index in
                                        Image(uiImage: previewImages[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                                            .background(Color.white)
                                            .tag(index)
                                            .opacity(isLoading ? 0 : 1)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .allowsHitTesting(!(isLoading || isSaving))  // Disable swipe during loading/saving
                                
                                if !isLoading {
                                    // Top border
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: UIScreen.main.bounds.width, height: 1)
                                        .position(x: UIScreen.main.bounds.width/2, y: (UIScreen.main.bounds.height * 0.6 - imageHeight)/2)
                                    
                                    // Bottom border
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: UIScreen.main.bounds.width, height: 1)
                                        .position(x: UIScreen.main.bounds.width/2, y: (UIScreen.main.bounds.height * 0.6 + imageHeight)/2)
                                }
                                
                                if isLoading {
                                    VStack {
                                        ProgressView()
                                            .scaleEffect(1.5)
                                            .tint(.white)
                                        Text("Processing...")
                                            .foregroundColor(.white)
                                            .padding(.top, 8)
                                        if !processingProgress.isEmpty {
                                            Text(processingProgress)
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 0)
                                }
                            }
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.6)
                        .padding(.vertical, 20)
                        .ignoresSafeArea(.all, edges: [.leading, .trailing])
                        .padding(.horizontal, 0)
                    } else {
                        // Guide View
                        VStack(alignment: .leading, spacing: 24) {
                            Text("How to use:")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                GuideStep(number: 1, text: "Select images from your library")
                                GuideStep(number: 2, text: "Choose your desired frame shape to place your image in")
                                GuideStep(number: 3, text: "Save framed images back to your library")
                                GuideStep(number: 4, text: "Enjoy posting your images in social media without getting them clipped")
                            }
                            
                            Spacer().frame(height: 24)
                            
                            Text("Note: We process the images directly on your phone, so your data is staying with you!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                        .padding(32)
                    }
                }
                
                if !previewImages.isEmpty && !isLoading {
                    VStack(spacing: 4) {
                        Spacer().frame(height: 32)
                        // Page indicator
                        ZStack(alignment: .leading) {
                            // Background track
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: UIScreen.main.bounds.width / 3, height: 3)
                                .cornerRadius(1.5)
                            
                            // Moving indicator
                            let totalWidth = UIScreen.main.bounds.width / 3
                            let segmentWidth = totalWidth / CGFloat(max(1, previewImages.count))
                            let xOffset = segmentWidth * CGFloat(selectedImageIndex)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: segmentWidth, height: 3)
                                .cornerRadius(1.5)
                                .offset(x: xOffset)
                                .animation(.easeInOut(duration: 0.2), value: selectedImageIndex)
                        }
                        
                        Text("\(selectedImageIndex + 1) of \(previewImages.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            // Bottom buttons and indicators
            VStack {
                Spacer()
                
                HStack {
                    if !previewImages.isEmpty {
                        Button(action: {
                            saveImagesToGallery(images: previewImages)
                        }) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .disabled(isLoading || isSaving)
                    }
                    
                    Spacer()
                    
                    // Start here indicator
                    if imageDataArray.isEmpty {
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Start here")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                            .modifier(PulseAnimation())
                        }
                    }
                    
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 20,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .disabled(isLoading || isSaving)
                    .onChange(of: selectedItems) { oldValue, newItems in
                        // Set loading state immediately
                        isLoading = true
                        processingProgress = "Loading photos..."
                        
                        Task {
                            // Handle deselection
                            if newItems.isEmpty {
                                isLoading = false
                                imageDataArray.removeAll()
                                previewImages.removeAll()
                                selectedImageIndex = 0
                                return
                            }
                            
                            // Load new images before clearing old ones
                            var newImageData: [Data] = []
                            for item in selectedItems {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    newImageData.append(data)
                                }
                            }
                            
                            await MainActor.run {
                                if !newImageData.isEmpty {
                                    // Only clear arrays after we have new data
                                    imageDataArray = newImageData
                                    selectedImageIndex = 0
                                    processAndPreviewImages()
                                } else {
                                    imageDataArray.removeAll()
                                    previewImages.removeAll()
                                    selectedImageIndex = 0
                                    isLoading = false
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            
            // Saving progress overlay
            if isSaving {
                ZStack {
                    Color.black.opacity(0.7)
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text(saveMessage ?? "Saving...")
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 0)
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    // Update the processing function to handle multiple images
    private func processAndPreviewImages() {
        guard !imageDataArray.isEmpty, let selectedAspectRatio = selectedAspectRatio else { 
            isLoading = false
            return 
        }
        
        isLoading = true
        let currentImages = imageDataArray // Create a local copy to prevent race conditions
        var processedImages: [UIImage] = []
        processedImages.reserveCapacity(currentImages.count) // Pre-allocate array capacity
        
        // Process images one at a time
        func processNextImage(at index: Int, total: Int) {
            guard index < total else {
                DispatchQueue.main.async {
                    self.previewImages = processedImages
                    self.isLoading = false
                    self.processingProgress = ""
                }
                return
            }
            
            // Update progress
            DispatchQueue.main.async {
                self.processingProgress = "Processing image \(index + 1) of \(total)"
            }
            
            autoreleasepool {
                guard index < currentImages.count,
                      let image = UIImage(data: currentImages[index]),
                      let processedImage = processImage(image: image, aspectRatio: selectedAspectRatio) else {
                    // Skip failed image and continue processing
                    DispatchQueue.global(qos: .userInitiated).async {
                        processNextImage(at: index + 1, total: total)
                    }
                    return
                }
                
                processedImages.append(processedImage)
                
                // Process next image after a brief delay to allow memory cleanup
                DispatchQueue.global(qos: .userInitiated).async {
                    processNextImage(at: index + 1, total: total)
                }
            }
        }
        
        // Start processing on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            processNextImage(at: 0, total: currentImages.count)
        }
    }
    
    private func processImage(image: UIImage, aspectRatio: AspectRatio) -> UIImage? {
        autoreleasepool {
            let width = image.size.width
            let height = image.size.height
            
            // Calculate target size while maintaining aspect ratio
            let targetRatio = aspectRatio.ratio
            let imageRatio = width / height
            
            // Calculate dimensions that fit Instagram's limits
            let maxWidth = aspectRatio.maxWidth
            let maxHeight = aspectRatio.maxHeight
            
            // Calculate the target size based on Instagram's limits
            let targetWidth: CGFloat
            let targetHeight: CGFloat
            
            if targetRatio > imageRatio {
                // Image is too tall, fit to width
                targetWidth = min(width, maxWidth)
                targetHeight = targetWidth / targetRatio
            } else {
                // Image is too wide, fit to height
                targetHeight = min(height, maxHeight)
                targetWidth = targetHeight * targetRatio
            }
            
            // Ensure we don't exceed Instagram's limits
            let finalWidth = min(targetWidth, maxWidth)
            let finalHeight = min(targetHeight, maxHeight)
            
            let size = CGSize(width: finalWidth, height: finalHeight)
            
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                // Draw white background
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                
                // Calculate scaling to fit image within the background
                let scale = min(finalWidth / width, finalHeight / height)
                let scaledWidth = width * scale
                let scaledHeight = height * scale
                
                // Center the image
                let xOffset = (finalWidth - scaledWidth) / 2
                let yOffset = (finalHeight - scaledHeight) / 2
                
                // Draw image
                image.draw(in: CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight))
            }
        }
    }
    
    private func scaleToInstagramResolution(image: UIImage, aspectRatio: AspectRatio) -> UIImage? {
        autoreleasepool {
            let width = image.size.width
            let height = image.size.height
            
            // Always scale down if larger than Instagram's maximum dimensions
            let scaleFactor = min(
                aspectRatio.maxWidth / width,
                aspectRatio.maxHeight / height,
                1.0  // Never scale up, only down
            )
            
            // Only resize if we need to scale down
            if scaleFactor < 1.0 {
                let newWidth = width * scaleFactor
                let newHeight = height * scaleFactor
                
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: newWidth, height: newHeight))
                return renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: CGSize(width: newWidth, height: newHeight)))
                }
            }
            
            return image
        }
    }
    
    private func saveImagesToGallery(images: [UIImage]) {
        guard !images.isEmpty else { return }
        
        isSaving = true
        saveMessage = nil
        
        // Save images one by one to avoid memory pressure
        func saveNextImage(at index: Int, total: Int) {
            guard index < total else {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.saveMessage = "Saved \(total) images!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.saveMessage = nil
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                self.saveMessage = "Saving image \(index + 1) of \(total)..."
            }
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: images[index])
                request.creationDate = Date()
            }) { success, error in
                if success {
                    // Process next image immediately without delay
                    DispatchQueue.global(qos: .background).async {
                        saveNextImage(at: index + 1, total: total)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isSaving = false
                        self.saveMessage = "Error saving image"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.saveMessage = nil
                        }
                    }
                }
            }
        }
        
        // Request permission and start saving
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.saveMessage = "Please allow access to save photos"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.saveMessage = nil
                    }
                }
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                saveNextImage(at: 0, total: images.count)
            }
        }
    }
}

struct AspectRatio: Hashable {
    let name: String
    let ratio: CGFloat
    let maxWidth: CGFloat
    let maxHeight: CGFloat
}

// Helper view for guide steps
struct GuideStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// Improved animation modifier
struct PulseAnimation: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: isAnimating ? -5 : 0)  // Subtle horizontal movement
            .opacity(isAnimating ? 0.8 : 1.0)  // Less opacity change
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)  // Faster animation
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    ContentView()
}
