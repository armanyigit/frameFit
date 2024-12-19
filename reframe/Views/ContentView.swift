import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if !viewModel.previewImages.isEmpty {
                    // Aspect Ratio Selector
                    HStack(spacing: 16) {
                        ForEach(AspectRatio.presets, id: \.self) { ratio in
                            VStack(spacing: 4) {
                                Image(systemName: ratio.name == "Square" ? "square.fill" : 
                                                ratio.name == "Portrait" ? "rectangle.portrait.fill" : 
                                                "rectangle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.selectedAspectRatio == ratio ? .blue : .gray)
                                
                                Text(ratio.name)
                                    .font(.caption)
                                    .foregroundColor(viewModel.selectedAspectRatio == ratio ? .blue : .gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedAspectRatio == ratio ? Color.blue.opacity(0.1) : Color.clear)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedAspectRatio = ratio
                                    viewModel.processAndPreviewImages()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .disabled(viewModel.isLoading || viewModel.isSaving)
                    
                    Spacer().frame(height: 16)
                }
                
                // Image viewer and loading overlay
                ZStack {
                    if !viewModel.imageDataArray.isEmpty {
                        GeometryReader { geometry in
                            let imageHeight = viewModel.selectedAspectRatio.ratio != nil ? 
                                UIScreen.main.bounds.width / viewModel.selectedAspectRatio.ratio : 0
                            
                            ZStack(alignment: .center) {
                                // Image viewer
                                TabView(selection: $viewModel.selectedImageIndex) {
                                    ForEach(viewModel.previewImages.indices, id: \.self) { index in
                                        Image(uiImage: viewModel.previewImages[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.main.bounds.width, height: imageHeight)
                                            .background(Color.white)
                                            .tag(index)
                                            .opacity(viewModel.isLoading ? 0 : 1)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .allowsHitTesting(!viewModel.isSaving)
                                
                                if !viewModel.isLoading {
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
                                
                                if viewModel.isLoading {
                                    LoadingView(
                                        message: "Processing...",
                                        progress: viewModel.processingProgress
                                    )
                                }
                            }
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.6)
                        .padding(.vertical, 20)
                        .ignoresSafeArea(.all, edges: [.leading, .trailing])
                        .padding(.horizontal, 0)
                    } else {
                        GuideView()
                    }
                }
                
                if !viewModel.previewImages.isEmpty && !viewModel.isLoading {
                    PageIndicator(
                        currentPage: viewModel.selectedImageIndex,
                        totalPages: viewModel.previewImages.count
                    )
                }
                
                Spacer()
            }
            
            // Bottom buttons and indicators
            VStack {
                Spacer()
                
                HStack {
                    if !viewModel.previewImages.isEmpty {
                        Button(action: {
                            viewModel.saveImagesToGallery()
                        }) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .disabled(viewModel.isLoading || viewModel.isSaving)
                    }
                    
                    Spacer()
                    
                    PhotosPicker(
                        selection: $viewModel.selectedItems,
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
                            .pulseAnimation()
                    }
                    .disabled(viewModel.isLoading || viewModel.isSaving)
                    .onChange(of: viewModel.selectedItems) { _, _ in
                        viewModel.handlePhotoSelection()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            
            // Saving progress overlay
            if viewModel.isSaving {
                ZStack {
                    Color.black.opacity(0.7)
                    LoadingView(
                        message: viewModel.saveMessage ?? "Saving...",
                        progress: ""
                    )
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

#Preview {
    ContentView()
} 