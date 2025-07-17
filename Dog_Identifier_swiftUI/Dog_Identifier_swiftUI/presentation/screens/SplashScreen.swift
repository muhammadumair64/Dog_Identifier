//
//  SplashScreen.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 09/12/2024.
//

import SwiftUI
import Lottie

struct SplashScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack {
            VStack {
                ZStack{
//                    Image(ImageResource.splashImg)
//                        .resizable()
//                        .frame(width: 250 , height: 250)
//                        .padding(.trailing,30)
                    
                    LottieView(animation: .named(LottieHelper.splashInsectAnim.rawValue))
                        .playing()
                        .looping()
                    
                }.frame(height: 250)

              
                
                Text("Dog Identification")
                    .foregroundColor(.black)
                    .font(Font.custom(FontHelper.bold.rawValue, size: 24))
                    .bold()
                    .padding(.top,75)
                    .padding(.bottom,1)
                
                Text("Scan & Identify – Know Every Pup's Story")
                    .foregroundColor(.gray)
                    .font(Font.custom(FontHelper.regular.rawValue, size: 16))
                    .multilineTextAlignment(.center)

            }
            .padding(.bottom, 120)
        }
        .onAppear {
          
            AdsCounter.isFromSplash =  true
            _ = UserDefaultManager.shared.get(forKey: .currentUser) ?? 0
            let isSecondTime =  UserDefaultManager.shared.get(forKey: .secondLaunch) ?? false

//            
            UserDefaultManager.shared.set(false, forKey:         UserDefaultManager.Key.isPremiumUser)
            AppOpenAdManager.shared.loadAd()
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
//                if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
//                    AppOpenAdManager.shared.showAdIfAvailable(rootViewController: rootViewController) {
//                        // Code to run after the ad is dismissed
//                            navigationManager.pop()
//                            if !isSecondTime {
//               navigationManager.push(.onboardingScreen)
//                            } else {
//                        navigationManager.push(.mainTabView)
//                            }
//                    }
//                }
//                else {
                    navigationManager.pop()
                    if !isSecondTime {
                       navigationManager.push(.onboardingScreen)
                    } else {
                     navigationManager.push(.mainTabView)
                    }
//                }
            }
        }
    }
}

#Preview {
    SplashScreen(navigationManager: NavigationManager())
}
