import SwiftUI

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

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        GuideStep(number: 1, text: "Select images from your library")
        GuideStep(number: 2, text: "Choose your desired frame shape")
        GuideStep(number: 3, text: "Save framed images back to your library")
    }
    .padding()
} 