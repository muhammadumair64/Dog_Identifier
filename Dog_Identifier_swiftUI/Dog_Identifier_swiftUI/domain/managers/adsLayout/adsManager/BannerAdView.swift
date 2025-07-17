//
//  BannerAdView.swift
//  YourApp
//
//  Created by Developer on 2025-05-29.
//

import SwiftUI
import GoogleMobileAds
import CocoaLumberjack

// MARK: - Ad Status Enum

enum AdStatus {
    case loading, success, failure
}

// MARK: - Ad Format Enum

enum AdFormat {
    case standardBanner
    case largeBanner
    case mediumRectangle
    case fullBanner
    case leaderboard
    case fluid
    case adaptiveBanner

    var adSize: AdSize {
        switch self {
        case .standardBanner: return AdSizeBanner
        case .largeBanner: return AdSizeLargeBanner
        case .mediumRectangle: return AdSizeMediumRectangle
        case .fullBanner: return AdSizeFullBanner
        case .leaderboard: return AdSizeLeaderboard
        case .fluid: return AdSizeFluid
        case .adaptiveBanner:
            let width = UIScreen.main.bounds.width
            return currentOrientationAnchoredAdaptiveBanner(width: width)
        }
    }
}

// MARK: - BannerAdView (SwiftUI wrapper)

struct BannerAdView: View {
    let adUnitID: String
    let adFormat: AdFormat
    @State private var adStatus: AdStatus = .loading
    var onShow: () -> Void = {}

    @AppStorage("isPurchased") var isPurchased = false
    var isPro: Bool {
        UserDefaultManager.shared.get(forKey: .isPremiumUser) ?? false
    }

    var body: some View {
        if !isPurchased && !isPro {
            HStack {
                if adStatus != .failure {
                    GADBannerContainerView(adUnitID: adUnitID, adSize: adFormat.adSize, adStatus: $adStatus)
                        .frame(width: adFormat.adSize.size.width, height: adFormat.adSize.size.height)
                        .onChange(of: adStatus) { status in
                            if status == .success {
                                onShow()
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            Color.clear.frame(height: 0)
        }
    }
}

// MARK: - GADBannerContainerView (UIViewControllerRepresentable)

struct GADBannerContainerView: UIViewControllerRepresentable {
    let adUnitID: String
    let adSize: AdSize
    @Binding var adStatus: AdStatus

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let bannerView = BannerView(adSize: adSize)

        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = viewController
        bannerView.delegate = context.coordinator

        viewController.view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            bannerView.widthAnchor.constraint(equalToConstant: adSize.size.width),
            bannerView.heightAnchor.constraint(equalToConstant: adSize.size.height)
        ])

        DDLogInfo("Loading AdMob banner with unit ID: \(adUnitID)")
        bannerView.load(Request())

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates required
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        let parent: GADBannerContainerView

        init(_ parent: GADBannerContainerView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            DDLogInfo("✅ bannerViewDidReceiveAd")
            parent.adStatus = .success
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            DDLogError("❌ didFailToReceiveAdWithError: \(error.localizedDescription)")
            parent.adStatus = .failure
        }

        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            DDLogDebug("📈 bannerViewDidRecordImpression")
        }

        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            DDLogInfo("🖱️ bannerViewDidRecordClick")
        }

        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            DDLogDebug("🔍 bannerViewWillPresentScreen")
        }

        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            DDLogVerbose("📤 bannerViewWillDismissScreen")
        }

        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            DDLogVerbose("📥 bannerViewDidDismissScreen")
        }
    }
}


