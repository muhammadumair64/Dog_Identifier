import SwiftUI
import UIKit
import Lottie

struct LimitDialog: View {
    @ObservedObject var navigationManager: NavigationManager
    @Binding var isPresented: Bool
    var onAction: () -> Void
    @State var isExceed = false
    @State var count = 0
    @StateObject private var adsManager = AdsManager.shared

    var body: some View {
        if isPresented {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isPresented = false  // Dismiss when tapping outside
                        }
                    }

                // Dialog Content
                dialogContent
                    .frame(maxWidth: 300)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.scale)
                    .padding(.top ,-70)
            }
            .onAppear{
               count = UserDefaultManager.shared.get(forKey: .freeScans) ?? 0
            
                if(count < 3){
                    isExceed = false
                }else{
                    isExceed = true
                }
            }
            .animation(.easeInOut, value: isPresented)
            .edgesIgnoringSafeArea(.all)
        }
    }

    private var dialogContent: some View {
        VStack(spacing: 16) {
            // Lottie Animation Icon
            LottieView(animation: .named(LottieHelper.premium.rawValue))
                .playing()
                .looping()
                .frame(width: 120, height: 120)

            // Title
            Text("Free Scan Limit")
                .font(Font.custom(FontHelper.regular.rawValue, size: 16))
                .multilineTextAlignment(.center)

            // Message
            Text("Your have \(3 - count) free scans left. Get Premium to unlock unlimited scans")
                .font(Font.custom(FontHelper.regular.rawValue, size: 14))
                .multilineTextAlignment(.center)

            // Continue Button
            Button(action: {
                isPresented = false
                if isExceed {
                    navigationManager.push(.premiumScreen)
                    AdsCounter.showProCounter = 0
                } else {
                    if(AdsCounter.shouldShowScanningAd()){
                        adsManager.interAdCallForScreen {
                            onAction()
                        }
                    }else{
                        onAction()
                    }
                }
            }) {
                Text("Continue")
                    .font(Font.custom(FontHelper.bold.rawValue, size: 18))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(ColorHelper.primary.color)
                    .cornerRadius(8)
            }
        }
        .padding(24)
    }
}
