import SwiftUI

struct AspectRatio: Hashable {
    let name: String
    let ratio: CGFloat
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    
    static let presets: [AspectRatio] = [
        AspectRatio(name: "Square", ratio: 1, maxWidth: 1080, maxHeight: 1080),
        AspectRatio(name: "Portrait", ratio: 4/5, maxWidth: 1080, maxHeight: 1350),
        AspectRatio(name: "Landscape", ratio: 16/9, maxWidth: 1080, maxHeight: 608)
    ]
    
    static var defaultRatio: AspectRatio {
        return presets[1] // Portrait as default
    }
} 