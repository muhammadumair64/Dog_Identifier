import UIKit
import GoogleMobileAds
import CocoaLumberjack

class AdsManager: NSObject, ObservableObject {
    
    enum NativeAdType {
        case regularType, mediumType, smallType, noMediaMedium
    }
    
    static let shared = AdsManager()
    
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var alertController: UIAlertController?
    
    @Published var isLoading: Bool = false  // New published property to track loading state
    
    private var onAdDismissed: (() -> Void)?  // Closure to handle dismissal
    
    private override init() {
        super.init()
        MobileAds.shared.start(completionHandler: nil)
    }
    
    func interAdCallForScreen(interAd : String = AdUnit.interstitial.unitId ,onAction: @escaping () -> Void){
        var isPro = UserDefaultManager.shared.get(forKey: .isPremiumUser) ??  false
        if(isPro){
            onAction()
            return
        }
        if let rootViewController = UIApplication.shared.getRootViewController() {
            DDLogDebug("before Load call")
            loadInterstitialAd(adUnitID: interAd, from: rootViewController) { success in
                if success {
                    DDLogDebug("Interstitial ad before show call")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.showInterstitialAd(from: rootViewController) {
                            // Navigate when 100% progress is reached
                            onAction()
                        }
                    }
                } else {
                    DDLogError("Failed to load interstitial ad.")
                }
            }
        } else {
            DDLogError("RootViewController is nil.")
        }
    }
    
    // MARK: - Interstitial Ads
    func loadInterstitialAd(adUnitID: String, from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        self.isLoading = true  // Set loading to true when starting to load the ad
        
        let request = Request()
        InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            self.isLoading = false  // Set loading to false when the ad loading finishes
            
            if let error = error {
                DDLogError("Failed to load interstitial ad: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self  // Set delegate for callbacks
            DDLogInfo("Interstitial ad loaded successfully.")
            completion(true)
        }
    }
    
    func showInterstitialAd(from viewController: UIViewController, onAdDismissed: @escaping () -> Void) {
        self.onAdDismissed = onAdDismissed // Store the closure
        
        guard let interstitialAd = interstitialAd else {
            DDLogWarn("Interstitial ad is not ready.")
            onAdDismissed()  // Call the closure immediately if the ad isn't ready
            return
        }

        interstitialAd.present(from: viewController)
        
        // Set up delegate methods for handling the dismissal and failure
        interstitialAd.fullScreenContentDelegate = self
    }

    // MARK: - Rewarded Ads
    func loadRewardedAd(adUnitID: String, from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        self.isLoading = true  // Set loading to true when starting to load the ad
        
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            self.isLoading = false  // Set loading to false when the ad loading finishes
            
            if let error = error {
                DDLogError("Failed to load rewarded ad: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            self.rewardedAd = ad
            DDLogInfo("Rewarded ad loaded successfully.")
            completion(true)
        }
    }
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd else {
            DDLogWarn("Rewarded ad is not ready.")
            completion(false)
            return
        }
        
        rewardedAd.present(from: viewController) {
            let reward = rewardedAd.adReward
            DDLogInfo("Reward received: \(reward.amount) \(reward.type)")
            completion(true)
        }
        self.rewardedAd = nil
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdsManager: FullScreenContentDelegate {
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        DDLogError("Ad failed to present full screen content: \(error.localizedDescription)")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        DDLogInfo("Ad dismissed full screen content.")
        AdsCounter.isShowOpenAd =  true
        // Check if it was an interstitial ad that was dismissed
        if ad is InterstitialAd {
            onAdDismissed?() // Safely call the closure if it exists
        }
    }
    
    func adDidShowFullScreenContent(_ ad: FullScreenPresentingAd) {
        DDLogInfo("Ad showed full screen content.")
        AdsCounter.isShowOpenAd =  false
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        DDLogInfo("Ad will dismiss full screen content.")
    }
}

// MARK: - GADAdLoaderDelegate

extension AdsManager: AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DDLogError("Failed to load native ad: \(error.localizedDescription)")
        self.isLoading = false
    }
}

// MARK: - GADNativeAdLoaderDelegate

extension AdsManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DDLogInfo("Native ad loaded: \(nativeAd.headline ?? "No headline available")")
        self.isLoading = false
    }
}

