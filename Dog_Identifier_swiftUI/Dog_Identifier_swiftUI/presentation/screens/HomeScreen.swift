//
//  HomeScreen.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 21/04/2025.
//

import SwiftUI

struct HomeScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var postViewModel: PostViewModel
    @ObservedObject var commonViewModel: CommonViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    @StateObject private var adsManager = AdsManager.shared
    @State private var selectedImage: UIImage? = nil
    @State private var isDialogPresented: Bool = false  // Dialog presentation flag
    @State private var isShowLimitDialog :Bool = false
    var isPro = UserDefaultManager.shared.get(forKey: .isPremiumUser) ??  false
    var body: some View {
        VStack{
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    ScanNowCard(imageWidth: 75, showButton: true, maxHeight: 155, textSpacing: 2)
                        .onTapGesture {
                        //   isDialogPresented = true
                            isShowLimitDialog = true
                        }

                    AdSectionView(
                        adUnitID: AdUnit.nativeNoMedia.unitId,
                        layout: .small,
                        rootViewController: UIApplication.shared.rootVC
                    )
                    .padding()
//                    
//                    CollapsibleBannerAdView(adUnitID: "ca-app-pub-3940256099942544/8388050270")
//                               .frame(minHeight: 50)
                    
//                    BannerAdView(adUnitID:AdUnit.homeBanner.unitId,adFormat: AdFormat.fluid)
                        

                    BlogsListView(viewModel: commonViewModel, navigationManager: navigationManager)

                

                    // ✅ Add bottom spacing here
                    Spacer().frame(height: 100)
                }
            }

        }
        .overlay(
            adsManager.isLoading ? LoadingDialogView() : nil
        )
        .overlay{
    
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
        .onAppear {
            // Load and show an interstitial ad if it hasn't been shown yet
            var isPro = UserDefaultManager.shared.get(forKey: .isPremiumUser) ?? false
            if(!isPro){
                if AdsCounter.shouldShowPro() {
                    navigationManager.push(.premiumScreen)
                }
            }
        }
        
    }
}

struct BlogsListView: View {
    @ObservedObject var viewModel: CommonViewModel
    @ObservedObject var navigationManager: NavigationManager

    var body: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("_getStarted", comment: ""))
                .font(.custom(FontHelper.extrabold.rawValue, size: 16))
                .bold()
                .foregroundColor(ColorHelper.darkText.color)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .padding(.leading, 15)

            ScrollView(.horizontal, showsIndicators: false) { // Horizontal scroll
                LazyHStack() {
                    ForEach(viewModel.blogs, id: \.id) { blog in
                        BlogListItem(image: blog.image, title: blog.Title, subTitle: blog.Date)
                            .frame(width: 220)
                            .padding(.leading,15)
                            .onTapGesture {
                            
                                if(AdsCounter.shouldShowAd()){
                                    AdsManager.shared.interAdCallForScreen {
                                        viewModel.fetchDetail(for: blog.id)
                                        navigationManager.push(.blogDetailScreen)
                                    }
                                }else {
                                    viewModel.fetchDetail(for: blog.id)
                                    navigationManager.push(.blogDetailScreen)
                                }
                            }
                    }
                }
                .padding(.bottom, 10)
            }
        }
    }

    struct BlogListItem: View {
        var image: String
        var title: String
        var subTitle: String

        var body: some View {
            VStack(alignment: .leading) {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 140) // Image size
                    .clipped()
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom(FontHelper.bold.rawValue, size: 14))
                        .foregroundColor(ColorHelper.darkText.color)
                        .lineLimit(1)

                    Text(subTitle)
                        .font(.custom(FontHelper.medium.rawValue, size: 12))
                        .foregroundColor(ColorHelper.lightText.color)
                        .lineLimit(1)

                    Text(NSLocalizedString("Read More", comment: ""))
                        .font(.custom(FontHelper.medium.rawValue, size: 12))
                        .foregroundColor(ColorHelper.primary.color)
                        .padding(.top, 5)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorHelper.grayBG.color, lineWidth: 1)
            )
        }
    }
}

#Preview {
    HomeScreen(navigationManager: NavigationManager(),postViewModel: PostViewModel(),commonViewModel: CommonViewModel(),cameraViewModel: CameraViewModel())
}
