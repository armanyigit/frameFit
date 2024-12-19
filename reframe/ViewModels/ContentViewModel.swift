import SwiftUI
import PhotosUI

class ContentViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var imageDataArray: [Data] = []
    @Published var previewImages: [UIImage] = []
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var saveMessage: String? = nil
    @Published var selectedAspectRatio: AspectRatio
    @Published var selectedImageIndex: Int = 0
    @Published var processingProgress: String = ""
    
    init() {
        self.selectedAspectRatio = AspectRatio.defaultRatio
        UIDevice.forcePortrait()
    }
    
    func processAndPreviewImages() {
        guard !imageDataArray.isEmpty else { 
            isLoading = false
            return 
        }
        
        isLoading = true
        let currentImages = imageDataArray
        var previewImages: [UIImage] = []
        
        func processNextImage(at index: Int, total: Int) {
            guard index < total else {
                DispatchQueue.main.async {
                    self.previewImages = previewImages
                    self.isLoading = false
                    self.processingProgress = ""
                }
                return
            }
            
            DispatchQueue.main.async {
                self.processingProgress = "Loading image \(index + 1) of \(total)"
            }
            
            autoreleasepool {
                guard index < currentImages.count,
                      let image = UIImage(data: currentImages[index]),
                      let previewImage = ImageProcessor.createPreviewImage(image: image, aspectRatio: selectedAspectRatio) else {
                    DispatchQueue.global(qos: .userInitiated).async {
                        processNextImage(at: index + 1, total: total)
                    }
                    return
                }
                
                previewImages.append(previewImage)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    processNextImage(at: index + 1, total: total)
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            processNextImage(at: 0, total: currentImages.count)
        }
    }
    
    func saveImagesToGallery() {
        guard !previewImages.isEmpty else { return }
        
        isSaving = true
        saveMessage = nil
        
        func processAndSaveNextImage(at index: Int, total: Int) {
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
                self.saveMessage = "Processing and saving image \(index + 1) of \(total)..."
            }
            
            guard let originalImage = UIImage(data: imageDataArray[index]),
                  let processedImage = ImageProcessor.processForSaving(image: originalImage, aspectRatio: selectedAspectRatio) else {
                processAndSaveNextImage(at: index + 1, total: total)
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: processedImage)
                request.creationDate = Date()
            }) { success, error in
                if success {
                    DispatchQueue.global(qos: .background).async {
                        processAndSaveNextImage(at: index + 1, total: total)
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
                processAndSaveNextImage(at: 0, total: self.previewImages.count)
            }
        }
    }
    
    func handlePhotoSelection() {
        // Set loading state immediately before any async work
        isLoading = true
        processingProgress = "Loading photos..."
        
        Task {
            // Handle deselection
            if selectedItems.isEmpty {
                imageDataArray.removeAll()
                previewImages.removeAll()
                selectedImageIndex = 0
                isLoading = false
                return
            }
            
            // Load new images
            for item in selectedItems {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        imageDataArray.append(data)
                    }
                }
            }
            
            if !imageDataArray.isEmpty {
                await MainActor.run {
                    processAndPreviewImages()
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
} 