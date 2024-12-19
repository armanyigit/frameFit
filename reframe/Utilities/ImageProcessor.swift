import UIKit

struct ImageProcessor {
    static func createPreviewImage(image: UIImage, aspectRatio: AspectRatio) -> UIImage? {
        autoreleasepool {
            let targetRatio = aspectRatio.ratio
            let size = CGSize(
                width: UIScreen.main.bounds.width,
                height: UIScreen.main.bounds.width / targetRatio
            )
            
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                // Draw white background
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                
                // Calculate scaling to fit image
                let imageRatio = image.size.width / image.size.height
                let drawSize: CGSize
                
                if targetRatio > imageRatio {
                    drawSize = CGSize(
                        width: size.height * imageRatio,
                        height: size.height
                    )
                } else {
                    drawSize = CGSize(
                        width: size.width,
                        height: size.width / imageRatio
                    )
                }
                
                // Center the image
                let xOffset = (size.width - drawSize.width) / 2
                let yOffset = (size.height - drawSize.height) / 2
                
                image.draw(in: CGRect(x: xOffset, y: yOffset, width: drawSize.width, height: drawSize.height))
            }
        }
    }
    
    static func processForSaving(image: UIImage, aspectRatio: AspectRatio) -> UIImage? {
        autoreleasepool {
            // Create frame at Instagram's maximum dimensions
            let targetSize = CGSize(
                width: aspectRatio.maxWidth,
                height: aspectRatio.maxHeight
            )
            
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { context in
                // Draw white background
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: targetSize))
                
                // Calculate scaling to fit image while maintaining aspect ratio
                let imageRatio = image.size.width / image.size.height
                let targetRatio = aspectRatio.ratio
                let drawSize: CGSize
                
                if targetRatio > imageRatio {
                    drawSize = CGSize(
                        width: targetSize.height * imageRatio,
                        height: targetSize.height
                    )
                } else {
                    drawSize = CGSize(
                        width: targetSize.width,
                        height: targetSize.width / imageRatio
                    )
                }
                
                // Center the image
                let xOffset = (targetSize.width - drawSize.width) / 2
                let yOffset = (targetSize.height - drawSize.height) / 2
                
                // Draw image
                image.draw(in: CGRect(x: xOffset, y: yOffset, width: drawSize.width, height: drawSize.height))
            }
        }
    }
} 