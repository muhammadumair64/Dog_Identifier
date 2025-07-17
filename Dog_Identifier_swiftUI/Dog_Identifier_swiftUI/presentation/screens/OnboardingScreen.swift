//
//  OnboardingScreen.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 10/12/2024.
//

import SwiftUI
import CocoaLumberjack

struct OnboardingScreen: View {
    
    @State private var currentPage = 0
    @ObservedObject var navigationManager: NavigationManager
    @State var subTitle = NSLocalizedString("_onboarding1_des", comment: "")
    @State var totalPages = 3
    
    
    private func getSubTitle() -> String {
        switch currentPage {
        case 0:
            return NSLocalizedString("_onboarding1_des", comment: "")
        case 1:
            return NSLocalizedString("_onboarding2_des", comment: "")
        case 2:
            return NSLocalizedString("_onboarding3_des", comment: "")
        default:
            return NSLocalizedString("_onboarding1_des", comment: "")
        }
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                TabView(selection: $currentPage) {
                    onboardingPage(imageName: ImageResource.onboarding1, index: 0)
                    onboardingPage(imageName: ImageResource.onboarding2, index: 1)
                    onboardingPage(imageName: ImageResource.onboarding3, index: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                HStack{
                                    Spacer()
                                    Text(NSLocalizedString("_skip", comment: ""))
                                           .frame(width: 65, height: 30)
                                           .foregroundColor(Color.black)
                                           .background(Color(hex: "#FFF8D1"))
                                           .cornerRadius(15)
                                           .font(Font.custom(FontHelper.regular.rawValue, size: 12))
                                           .multilineTextAlignment(.center)
                                           .overlay(
                                               RoundedRectangle(cornerRadius: 20)
                                                   .stroke(Color.orange, lineWidth: 1)
                                           )
                                           .padding(10)
                                           .contentShape(Rectangle())
                                       
                                           .onTapGesture {
                                               print("Skip button tapped!")
                                               navigationManager.push(.mainTabView)
                                           }
                                           .padding(.top,50)
                
                                }
                    .padding(.horizontal,20)
                
                VStack{
                    HStack {
                        TopView(currentPage: $currentPage)
                        Spacer()
                    } .frame(width: .infinity,height: 90)
            
                    Spacer()
                }.frame(maxHeight: .infinity)

    
                
                VStack() {
                    Spacer()
                    SkipAndNextView(
                        currentPage:  $currentPage
                        , totalPages: $totalPages,
                        onSkip: {
                            print("Skip button tapped!")
                            navigationManager.push(.mainTabView)
                        },
                        onNext: {
                            print("Next button tapped!")
                            if currentPage < totalPages - 1 {
                                currentPage += 1
                            } else {
                                navigationManager.push(.mainTabView)
                            }
                        }
                    )
        
                    
                    AdSectionView(
                        adUnitID: AdUnit.nativeNoMedia.unitId, // <-- your ad unit ID
                        layout: .small,
                          rootViewController: UIApplication.shared.rootVC
                      )
                    .padding(.horizontal)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom,20)
                
            }
        }
    }
}

struct TopView: View {
    @Binding var currentPage: Int

    var body: some View {
        VStack(alignment: .leading) {
            getTitleText(for: currentPage)
        }
        .padding(.leading, 20)
    }

    private func getTitleText(for page: Int) -> Text {
        switch page {
        case 0:
            DDLogInfo("TopView: Showing text for page 0")
            return Text("Scan to ")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
            + Text("Uncover the Secrets")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
                .foregroundColor(.orange)
            + Text("\nof Your Dog's Breed")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
            
        case 1:
            DDLogInfo("TopView: Showing text for page 1")
            return Text("Share yoour ")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
            + Text("Dog's Beautiful ")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
                .foregroundColor(.orange)
            + Text("\nMoments")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
            
        case 2:
            DDLogInfo("TopView: Showing text for page 2")
            return Text("Get to Know ")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
            + Text("400+ Different ")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
                .foregroundColor(.orange)
            + Text("\nDog's Breed")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
        
        default:
            DDLogWarn("TopView: Unexpected page index \(page)")
            return Text("Welcome")
                .font(Font.custom(FontHelper.sfBold.rawValue, size: 24))
        }
    }
}



struct SkipAndNextView: View {
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var onSkip: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil

    
    var body: some View {
        HStack {
            if(currentPage != 0){
                Button(action: {
                    currentPage  = currentPage - 1
                }) {
                    Image(ImageResource.previousArrow)
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                }
            } else {
                HStack{}
                    .frame(width: 70, height: 70)
            }

    
            Spacer()
            
            CustomPagingIndicator(currentPage: currentPage, totalPages: totalPages)
            
            Spacer()
            
            Button(action: {
                onNext?()
            }) {
                ZStack {
                    Image(ImageResource.nextArrow)
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 25)
        .frame(maxWidth: .infinity, maxHeight: 70)
    }
}

// MARK: - Onboarding Page
private func onboardingPage(imageName: ImageResource, index: Int) -> some View {
    VStack {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 250)
    }
    .tag(index)
}

#Preview {
    OnboardingScreen(navigationManager: NavigationManager())
}
