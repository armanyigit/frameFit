import SwiftUI

struct LoadingView: View {
    let message: String
    let progress: String
    
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text(message)
                .foregroundColor(.white)
                .padding(.top, 8)
            if !progress.isEmpty {
                Text(progress)
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

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        LoadingView(message: "Processing...", progress: "2 of 5")
    }
} 