import SwiftUI

struct CollectionDetailsScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var postViewModel: PostViewModel
    @State var refreshAd = false
    var body: some View {
        VStack{
            NavigationBarView(navigationManager: navigationManager, title: postViewModel.selectedCollection?.name ?? "Unknown")
//            if refreshAd {
//                NativeAdView(adType: .withoutMedia)
//                    .frame(maxHeight: 200)
//                    .background(ColorHelper.primary.color.opacity(0.1))
//                    .cornerRadius(20)
//                
//            }
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Navigation Bar

                    // Image Section
                    if let imageData = postViewModel.selectedCollection?.image, let uiImage = UIImage(data: imageData)?.fixOrientation() {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 250)
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                    }
                    
                    // Description Text
                    Text(postViewModel.selectedCollection?.insectDesciption ?? "")
                        .font(.custom(FontHelper.medium.rawValue, size: 14))
                        .foregroundColor(ColorHelper.darkText.color)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.leading) // Ensures proper text wrapping
                    
               
                    
                }
                .padding(.vertical, 20) // Padding around the VStack
            }
        }

        .onAppear{
            refreshAd = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                refreshAd = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
       
    }
}

#Preview {
    CollectionDetailsScreen(navigationManager: NavigationManager(), postViewModel: PostViewModel())
}
