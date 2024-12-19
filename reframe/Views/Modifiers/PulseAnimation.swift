import SwiftUI

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

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
}

#Preview {
    Text("Tap me!")
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .pulseAnimation()
} 