import SwiftUI

struct CustomProgressBar: View {
    @Binding var progress: Double // Progress value between 0.0 and 1.0
    var thumbImage: String // The name of the thumb image resource

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                
                // Background track
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 10)
                
                // Progress track
                Capsule()
                    .fill(Color.blue)
                    .frame(width: CGFloat(progress) * geometry.size.width, height: 10)
                
                // Thumb
                if progress > 0 { // Prevent thumb from appearing at 0% progress
                    Image(thumbImage)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .offset(x: CGFloat(progress) * geometry.size.width - 15) // Center thumb
                }
            }
            
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newProgress = min(max(0.0, value.location.x / geometry.size.width), 1.0)
                        progress = newProgress
                    }
            )
        }
        .frame(height: 30) // Ensure enough height for the thumb image
        .padding(.horizontal, 20)
    }
}

struct CustomProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomProgressBar(progress: .constant(0.5), thumbImage: "thumbImageName")
            .frame(height: 50) // To make the preview more visible
    }
}
