//
//  IdentifyScreen.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 21/04/2025.
//
import SwiftUI
import Lottie
import CocoaLumberjack
import SDWebImageWebPCoder

struct IdentifyScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var commonViewModel: CommonViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    var isPro = UserDefaultManager.shared.get(forKey: .isPremiumUser) ??  false
    @StateObject private var adsManager = AdsManager.shared
    @State private var selectedImage: UIImage? = nil
    @State private var isDialogPresented: Bool = false  // Dialog presentation flag
    @State private var isShowLimitDialog :Bool = false
    var body: some View {
        ScrollView { // Added ScrollView for safe content handling
            VStack {
                HStack(spacing: 16) {
                    
                    ScanNowCardSmall(
                        imageWidth: 80,
                        showButton: true,
                        maxHeight: 200,
                        textSpacing: 6,
                        onTap : {
                            isShowLimitDialog = true
                        }
                    ).onTapGesture {
                        isShowLimitDialog = true 
                    }
                    
                    
                    ViewNowCardSmall(
                        imageWidth: 80,
                        showButton: true,
                        maxHeight: 200,
                        textSpacing: 6,
                        onTap : {
                            navigationManager.push(.knowAboutScreen)
                        }
                    ).onTapGesture {
                        navigationManager.push(.knowAboutScreen)
                    }
                    
                }
                .padding(.horizontal, 10) // safe side padding
         
//                if let path = Bundle.main.path(forResource: "affenpinscher", ofType: "webp"),
//                   let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
//                   let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil) {
//                    Image(uiImage: image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 100,height: 100)
//                }
                AdSectionView(
                    adUnitID: AdUnit.nativeNoMedia.unitId, // <-- your ad unit ID
                    layout: .small,
                      rootViewController: UIApplication.shared.rootVC
                  )
                  .padding()
                FamousBreedView(commonViewModel: commonViewModel,navigationManager: navigationManager)
                Spacer()
            }
        }
        .overlay{
            AdsManager.shared.isLoading ? LoadingDialogView() : nil
             // Show the dialog overlay
            DialogPicker(selectedImage: $selectedImage, isPresented: $isDialogPresented)
            
            
            if(isPro && isShowLimitDialog  ){
                Color.clear.onAppear{
                    isDialogPresented = true
                    isShowLimitDialog =  false
                }
            }else{
                LimitDialog(navigationManager:navigationManager , isPresented: $isShowLimitDialog) {
                    isDialogPresented = true
                }
            }
  
        }
        .onChange(of: selectedImage) { value in
            cameraViewModel.capturedImage = value
            navigationManager.push(.scanningScreen)
        }
        .onChange(of: isShowLimitDialog){ newValue in
            commonViewModel.isShowingDialog = newValue
        }
        .overlay(
            adsManager.isLoading ? LoadingDialogView() : nil
        )
    }
}


struct FamousBreedView: View {
    @ObservedObject var commonViewModel: CommonViewModel
    @ObservedObject var navigationManager: NavigationManager
    let breeds = LocalLists.famousDogList()
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    @StateObject private var adsManager = AdsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Some famous breeds")
                .font(Font.custom(FontHelper.regular.rawValue, size: 18))

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(breeds) { breed in
                    BreedCardView(breed: breed)
                        .onTapGesture {
                            let targetBreedName = breed.name.lowercased()
                            let matchedDog = commonViewModel.dogs.first { dog in
                                dog.breedName.lowercased() == targetBreedName
                            }
                            commonViewModel.selectedDog = matchedDog
                            if(matchedDog != nil ){
                                if(AdsCounter.shouldShowAd()){
                                    adsManager.interAdCallForScreen {
                                        navigationManager.push(.dogDetailScreen)
                                    }
                                } else {
                                    navigationManager.push(.dogDetailScreen)
                                }
                     
                            }
                        }

                }

                // "View More" card
                Button(action: {
                    DDLogInfo("View More button tapped")
                    navigationManager.push(.knowAboutScreen)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange, lineWidth: 1)
                            .background(Color.white)
                            .cornerRadius(16)

                        Text("View More")
                            .font(Font.custom(FontHelper.regular.rawValue, size: 16))
                            .foregroundColor(.orange)
                    }
                    .frame(height: 80)
                }

                // Spacer to prevent bottom clipping
                Color.clear
                    .frame(height: 100)
            }
        }
        .padding()
    }
}



struct BreedCardView: View {
    let breed: FamousDog

    var body: some View {
        HStack {
            Text(breed.name)
                .font(Font.custom(FontHelper.regular.rawValue, size: 12))
                .foregroundColor(.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Image(breed.imageName ?? "german_shepherd")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 80) // 🔐 Fixed height
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.gray.opacity(0.10), radius: 2, x: 0, y: 1)
    }
}



struct ScanNowCardSmall: View {
    // MARK: - Properties
    
    var imageWidth: CGFloat = 40
    var showButton: Bool = true
    var maxHeight: CGFloat = 200
    var textSpacing: CGFloat = 8

    var onTap: (() -> Void)? = nil
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color(hex: "#FFD2B4"))
                
                LottieView(animation: .named(LottieHelper.card_lottie.rawValue))
                    .playing()
                    .looping()
                    .frame(width: 65, height: 65)
            }
            .frame(width: imageWidth, height: imageWidth)

            VStack(alignment: .center, spacing: textSpacing) {
                Text(NSLocalizedString("Identify dog breed", comment: ""))
                    .font(Font.custom(FontHelper.sfBold.rawValue, size: 14))
                    .foregroundColor(ColorHelper.darkText.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)

                Text(NSLocalizedString("Quickly & accurately identify any dog breed", comment: ""))
                    .font(Font.custom(FontHelper.medium.rawValue, size: 12))
                    .foregroundColor(ColorHelper.lightText.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .fixedSize(horizontal: false, vertical: true) // Allow multi-line wrapping
            }
            .frame(maxWidth: .infinity)

            if showButton {
                Button(action: {
                    DDLogInfo("Scan Now Button tapped")
                    onTap?()
                }) {
                    HStack { }
                        .frame(height: 30)
                        .frame(maxWidth: .infinity)
                        .background(
                            Image(ImageResource.scanAgainSmall)
                                .resizable()
                                .scaledToFit()
                        )
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(width: (UIScreen.main.bounds.width / 2) - 24, height: maxHeight)
        .background(
            Image(ImageResource.scanAgainCardBg)
                .resizable()
                .scaledToFill()
        )
        .cornerRadius(16)
        .shadow(color: Color.gray.opacity(0.15), radius: 6, x: 0, y: 4)
        .padding(.vertical, 8)
  
    }
}

struct ViewNowCardSmall: View {
    // MARK: - Properties
    
    var imageWidth: CGFloat = 40
    var showButton: Bool = true
    var maxHeight: CGFloat = 200
    var textSpacing: CGFloat = 8

    var onTap: (() -> Void)? = nil
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Image(ImageResource.blueDog)
                    .resizable()
                    .frame(width: 65, height: 65)
                    .padding(.top,5)
                    
            }
            .frame(width: imageWidth, height: imageWidth)

            VStack(alignment: .center, spacing: textSpacing) {
                Text(NSLocalizedString("Dogs Encyclopedia", comment: ""))
                    .font(Font.custom(FontHelper.sfBold.rawValue, size: 14))
                    .foregroundColor(ColorHelper.darkText.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)

                Text(NSLocalizedString("Over 100+ breeds in our data base.", comment: ""))
                    .font(Font.custom(FontHelper.medium.rawValue, size: 12))
                    .foregroundColor(ColorHelper.lightText.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .fixedSize(horizontal: false, vertical: true) // Allow multi-line wrapping
            }
            .frame(maxWidth: .infinity)

            if showButton {
                Button(action: {
                    DDLogInfo("Scan Now Button tapped")
                    onTap?()
                }) {
                    HStack { }
                        .frame(height: 30)
                        .frame(maxWidth: .infinity)
                        .background(
                            Image(ImageResource.viewNow)
                                .resizable()
                                .scaledToFit()
                        )
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(width: (UIScreen.main.bounds.width / 2) - 24, height: maxHeight)
        .background(
            Image(ImageResource.viewNowCardBg)
                .resizable()
                .scaledToFill()
        )
        .cornerRadius(16)
        .shadow(color: Color.gray.opacity(0.15), radius: 6, x: 0, y: 4)
        .padding(.vertical, 8)
  
    }
}


#Preview {
    IdentifyScreen(navigationManager: NavigationManager(), commonViewModel: CommonViewModel(),cameraViewModel: CameraViewModel())
}
