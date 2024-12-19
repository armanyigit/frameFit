import UIKit

extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static func forcePortrait() {
        if !isIPad {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                windowScene.requestGeometryUpdate(geometryPreferences)
            }
        }
    }
} 