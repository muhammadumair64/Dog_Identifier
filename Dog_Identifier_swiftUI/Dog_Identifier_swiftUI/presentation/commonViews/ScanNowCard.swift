import SwiftUI
import Lottie

struct ScanNowCard: View {
    var imageWidth: CGFloat
    var showButton: Bool
    var maxHeight: CGFloat
    var textSpacing: CGFloat

    var body: some View {
        HStack(spacing: 16) {
            
    
            ZStack{
                ZStack{
                    Circle()
                        .frame(width: 75 ,height: 75)
                        .foregroundColor(Color.init(hex: "#FFD2B4"))
                    LottieView(animation: .named(LottieHelper.card_lottie.rawValue))
                        .playing()
                        .looping()
                }.padding(.horizontal,-15)
            }.frame(width: 60)
                .padding(.leading,30)

            
            VStack(alignment: .trailing, spacing: 8) {
                
                VStack(alignment: .leading, spacing: textSpacing) {
                    Text(NSLocalizedString("_unable", comment: ""))
                        .font(.custom(FontHelper.sfBold.rawValue, size: 16))
                        .foregroundColor(ColorHelper.darkText.color)
                        .bold()
                        .padding(.top,5)

                    Text(NSLocalizedString("_quickly&", comment: ""))
                        .font(.custom(FontHelper.medium.rawValue, size: 13))
                        .foregroundColor(ColorHelper.lightText.color)
                }
                .frame(alignment: .leading)
                .padding(.bottom, 8)
                .padding(.trailing,20)
        
                
                if showButton {
                    HStack {} // Placeholder, use your MainButton component here
                        .frame(maxWidth: 210, maxHeight: 38)
                        .background(Image(ImageResource.scanNowBtn))
                        .padding(.leading,30)
                        .padding(.top,5)
                }
            }
        
            
            // Placeholder image section
//            Image(ImageResource.newScan)
//                .resizable()
//                .frame(width: imageWidth, height: imageWidth)
//                .padding(.trailing, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .leading)
        .background(
            HStack {}
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Image(ImageResource.scanNowBg)
                    .resizable())
        )
        .cornerRadius(12)
        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

struct ScanNowCard_Previews: PreviewProvider {
    static var previews: some View {
        ScanNowCard(
            imageWidth: 80,
            showButton: true,
            maxHeight: 180,
            textSpacing: 6
        )
        .background(Color.black) // Optional for better contrast
    }
}

