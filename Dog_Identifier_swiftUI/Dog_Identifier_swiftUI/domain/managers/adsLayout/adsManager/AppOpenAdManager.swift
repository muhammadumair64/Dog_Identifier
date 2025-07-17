import Foundation
import GoogleMobileAds
import SwiftUI
import CocoaLumberjack

class AppOpenAdManager: NSObject, ObservableObject {
    @Published var isAdReady = false
    @Published var isLoadingAd = false
    @Published var isShowingAd = false
    
    private var appOpenAd: AppOpenAd?
    private var loadTime: Date?
    private let adUnitID = AdUnit.openAd.unitId
    private var isAppInBackground = false
    private var shouldShowAdOnForeground = false
    private var completionHandler: (() -> Void)?
    
    static let shared = AppOpenAdManager()
    
    override init() {
        super.init()
        // Observe app state changes
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func isAdAvailable() -> Bool {
        guard appOpenAd != nil else { return false }
        let currentTime = Date()
        guard let loadTime = loadTime, currentTime.timeIntervalSince(loadTime) < 3600 else {
            DDLogInfo("Ad expired, reloading...")
            return false
        }
        return true
    }
    
    private func resetAdState() {
        appOpenAd = nil
        isShowingAd = false
        isLoadingAd = false
        isAdReady = false
    }
    
    func loadAd() {
        if isLoadingAd || isAdAvailable() {
            DDLogDebug("Ad is already loading or available.")
            return
        }
        isLoadingAd = true
        DDLogInfo("Start loading app open ad.")

        let request = Request()
        AppOpenAd.load(with: adUnitID, request: request) { [weak self] (ad, error) in
            guard let self = self else { return }
            self.isLoadingAd = false
            if let error = error {
                DDLogError("App open ad failed to load with error: \(error.localizedDescription).")
                return
            }
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.loadTime = Date()
            DDLogInfo("App open ad loaded successfully.")
            self.isAdReady = true
        }
    }
    
    func showAdIfAvailable(rootViewController: UIViewController, completion: @escaping () -> Void) {
        guard isAdAvailable() else {
            DDLogWarn("App open ad is not ready yet.")
            completion()
            return
        }
        
        if let ad = appOpenAd {
            // Check if rootViewController is presenting anything
            if rootViewController.presentedViewController != nil {
                DDLogWarn("Root view controller is presenting another view. Skipping ad.")
                completion()
                return
            }
            
            DDLogInfo("App open ad will be displayed.")
            isShowingAd = true
            self.completionHandler = completion

            ad.present(from: rootViewController)
        }
    }
    
    @objc private func appDidEnterBackground() {
        isAppInBackground = true
        shouldShowAdOnForeground = true
        DDLogInfo("App entered background.")
    }
    
    @objc private func appWillEnterForeground() {
        DDLogInfo("App will enter foreground.")
        
        guard shouldShowAdOnForeground else {
            DDLogDebug("Ad display skipped as app did not transition from background.")
            return
        }
        
        shouldShowAdOnForeground = false
        isAppInBackground = false
        if AdsCounter.isShowOpenAd {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Add slight delay
                if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                    self.showAdIfAvailable(rootViewController: rootViewController) {
                        DDLogInfo("Ad display completed or skipped.")
                    }
                }
            }
        } else {
            AdsCounter.isShowOpenAd =  true
        }
        
      
    }
}

extension AppOpenAdManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        DDLogInfo("App open ad will be presented.")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        DDLogInfo("App open ad was dismissed.")
        resetAdState()
        completionHandler?()
        loadAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        DDLogError("App open ad failed to present with error: \(error.localizedDescription).")
        resetAdState()
        completionHandler?()
        loadAd()
    }
}
