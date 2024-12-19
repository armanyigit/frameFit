import SwiftUI

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Spacer().frame(height: 32)
            
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: UIScreen.main.bounds.width / 3, height: 3)
                    .cornerRadius(1.5)
                
                // Moving indicator
                let totalWidth = UIScreen.main.bounds.width / 3
                let segmentWidth = totalWidth / CGFloat(max(1, totalPages))
                let xOffset = segmentWidth * CGFloat(currentPage)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: segmentWidth, height: 3)
                    .cornerRadius(1.5)
                    .offset(x: xOffset)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
            
            Text("\(currentPage + 1) of \(totalPages)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    PageIndicator(currentPage: 2, totalPages: 5)
} 