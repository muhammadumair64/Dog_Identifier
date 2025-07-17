import CocoaLumberjack
import SwiftUI

struct PremiumPlanView: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var commonViewModel: CommonViewModel
    var inAppManager: InAPPManager? = InAPPManager.shared
    @State var price = ""
    @State var showSuccessDialog = false
    @State var showRestoreAlert  = false
    @State var showNetworkDialog = false
    @State var restoreTitle = ""
    @State var restoreMessage = ""
    @State var isLoading = false
    let viewModel = AppSideMenuViewModel()
    @StateObject private var adsManager = AdsManager.shared
    var body: some View {
        ZStack {
            VStack {
                Image("bg_premium_img")
                    .resizable()
                    .frame(height: UIScreen.main.bounds.height * 0.60)
                Spacer()
            }

                VStack(spacing: 5) {
                    VStack{
                       //my Spacer
                    }.frame(maxHeight: 60)
                    HStack {
                        Text("Become a")
                            .font(.custom("Helvetica-Bold", size: 18))
                            .foregroundColor(.white)
                        Text("PRO")
                            .font(.custom("Helvetica-Bold", size: 18))
                            .foregroundColor(ColorHelper.primary.color)
                        Text("user!")
                            .font(.custom("Helvetica-Bold", size: 18))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Image("stars")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))  // Adjust icon size
                            .padding(.leading, 10)

                        Text("Unlock all features")
                            .font(.custom("Helvetica", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }

                }
         

            VStack {
                HStack {
                    Image("close")
                        .foregroundColor(.blue)
                        .font(.system(size: 38))  // Adjust icon size
                        .padding(.leading, 10)
                        .onTapGesture {
                            if(AdsCounter.isFromSplash){
                                AdsCounter.isFromSplash = false
                                adsManager.interAdCallForScreen(interAd: AdUnit.splashInter.unitId, onAction: {
                                    navigationManager.pop()
                                    
                                })
                            }else{
                                navigationManager.pop()
                            }

                        }

                    Spacer()
                    
                    Text("Restore")
                        .font(.custom("Helvetica-Bold", size: 18))
                        .frame(height: 30)
                        .foregroundColor(ColorHelper.primary.color)
                        .onTapGesture {
                            let isPro =  UserDefaultManager.shared.get(forKey: .isPremiumUser) ?? false
                            
                            if(isPro){
                                InAPPManager.shared.restoreSubscriptions()
                               restoreTitle = "Restore Successful"
                               restoreMessage = "subscription restored successfully"
                                showRestoreAlert = true
                            }else{
                                restoreTitle = "Restore Alert"
                                restoreMessage = "You currently have no active subscription. Please subscribe to continue."
                                 showRestoreAlert = true
                            }
                       
                        }
                }.padding(.top, 50)
                    .padding(.horizontal, 10)
                Spacer()
            }

            VStack {
                Spacer()
                // Features List
                VStack(spacing: 12) {
                    HStack {
                        FeatureButton(
                            icon: "dog 1",
                            text: "Dog Identification")
                        FeatureButton(icon: "unlimited_Scans", text: "Unlimited Posts")
                    }
                    .frame(maxWidth: .infinity)

                    HStack {
                        FeatureButton(icon: "removeAds", text: "Remove Ads")
                        FeatureButton(
                            icon: "supportPro", text: "VIP Customer Support")
                    }

                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.top, 30)
                .padding(.bottom, 10)

                // Pricing
                Text("Get Premium Version in \(price) /week")
                    .font(.custom("Helvetica", size: 14))
                    .foregroundColor(.gray)
                    .padding(.top)

                // Upgrade Button
//                Button(action: {
//                    // Upgrade Action
//                    InAPPManager.shared.Purchase(
//                        product: .pro_version_butterfly_identifier
//                    ) { price in
//                        UserDefaultManager.shared.set(
//                            true, forKey: .isPremiumUser)
//                        showSuccessDialog =  true
//                    }
//                }) {
//                    Text("Upgrade")
//                        .foregroundColor(.white)
//                        .font(.custom("Helvetica-Bold", size: 16))
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(ColorHelper.primary.color)
//                        .cornerRadius(10)
//                }
//                .padding(.horizontal)
//                .padding(.top, 5)
                
                UpgradeButtonView(navigationManager: navigationManager ,isLoading: $isLoading,showNetworkDialog: $showNetworkDialog)

                // Terms and Privacy Policy
                HStack {
                    Text("Terms of Services")
                        .underline()
                        .onTapGesture {
                            viewModel.showTerms()
                        }
                    Text("|")
                    
                    Text("Privacy Policy")
                        .underline()
                        .onTapGesture {
                            viewModel.showPolicy()
                        }
                }
                .font(.custom("Helvetica", size: 12))
                .foregroundColor(.gray)
                .padding(.top, 5)

                Text(
                    "Cancel anytime in the App Store at no additional cost, your subscription will then cease at the end of the current term."
                )
                .font(.custom("Helvetica", size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 5)
                .padding(.bottom, 5)
            }
            if isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Loading...")
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                            .shadow(radius: 5)
                    }
                }

        }
        .overlay(
            adsManager.isLoading ? LoadingDialogView() : nil
        )
        .onChange(of: showRestoreAlert){ newValue in
            if(newValue){
                AlertManager.shared.showAlert(
                    title:restoreTitle,
                    message: restoreMessage,
                    primaryButtonTitle: "OK",
                    primaryAction: {
//                        navigationManager.pop()
                        showRestoreAlert = false
                    },
                    showSecondaryButton: false
                )
            }
        }
        .onChange(of: showSuccessDialog){ newValue in
            if(newValue){
                AlertManager.shared.showAlert(
                    title: "Purchase Success",
                    message: "Subscription purchased successfully! Enjoy your premium access.",
                    primaryButtonTitle: "OK",
                    primaryAction: {
                        navigationManager.pop()
                        showNetworkDialog = false
                    },
                    showSecondaryButton: false
                )
            }
        }
        .onChange(of: showNetworkDialog){ newValue in
            if(newValue){
                AlertManager.shared.showAlert(
                    title: "Network Error",
                    message: "Please Check Your Internet Connection",
                    primaryButtonTitle: "OK",
                    primaryAction: {
//                        navigationManager.pop()
                        showSuccessDialog = false
                    },
                    showSecondaryButton: false
                )
            }
        }
        .onAppear {
            isLoading = false
            price = UserDefaultManager.shared.get(forKey: .PRICE) ?? ""
            DDLogDebug("Print my price : \(price)")
        }
        .ignoresSafeArea(edges: .top)
    }
}

struct UpgradeButtonView: View {
    @ObservedObject var navigationManager: NavigationManager
    @Binding var isLoading: Bool
    @Binding var showNetworkDialog:Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var isShaking = false
    @State private var showSuccessDialog = false

    var body: some View {
        Button(action: {
            InternetManager.shared.isInternetAvailable { isAvailable in
                if(isAvailable){
                    isLoading =  true
                    // Upgrade Action
                    InAPPManager.shared.Purchase(
                        product: .premium_dog
                    ) { price  , result in
                        if(result){
                            UserDefaultManager.shared.set(true, forKey: .isPremiumUser)
                            showSuccessDialog = true
                            isLoading =  false
                        }else{
                            isLoading =  false
                            navigationManager.pop()
                        }
                 
                    }
                }else{
                    showNetworkDialog = true
                    
                }
            }

        }) {
            Text("Start Now")
                .foregroundColor(.white)
                .font(.custom("Helvetica-Bold", size: 16))
                .padding()
                .frame(maxWidth: .infinity)
                .background(ColorHelper.primary.color)
                .cornerRadius(10)
                .offset(x: shakeOffset) // Apply the shake effect
        }
        .padding(.horizontal)
        .padding(.top, 5)
        .onAppear {
#if targetEnvironment(simulator)
    // Do nothing or log if needed
    DDLogInfo("Shake animation skipped: Running in Simulator.")
#else
    if UIDevice.current.userInterfaceIdiom == .phone {
        DDLogDebug("Shake animation started: Running on real iPhone device.")
        startShakeAnimation()
    } else {
        DDLogInfo("Shake animation skipped: Running on iPad.")
    }
#endif

        }
    }

    /// Function to start the shake animation loop
    private func startShakeAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // Shake for 2 seconds
            withAnimation(Animation.linear(duration: 0.1).repeatCount(5, autoreverses: true)) {
                shakeOffset = 10
            }

            // Reset shake after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shakeOffset = 0
            }
        }
    }
}



struct FeatureButton: View {
    var icon: String
    var text: String

    var body: some View {
        HStack {
            Image(icon)
                .foregroundColor(.blue)
                .font(.system(size: 18))  // Adjust icon size
                .padding(.leading, 10)

            Text(text)
                .font(.custom("Helvetica", size: 14))
                .foregroundColor(.black)
                .padding(.trailing, 10)
        }
        .frame(height: 40)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)  // Border instead of solid fill
        )
    }
}

struct PremiumPlanView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPlanView(
            navigationManager: NavigationManager(),
            commonViewModel: CommonViewModel())
    }
}
