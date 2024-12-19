import SwiftUI

struct GuideView: View {
    var body: some View {
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

#Preview {
    GuideView()
} 