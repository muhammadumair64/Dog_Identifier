//
//  CollapsibleBannerAdView.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 15/07/2025.
//



import SwiftUI
import GoogleMobileAds
import CocoaLumberjack

struct CollapsibleBannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            DDLogError("RootViewController not available for CollapsibleBannerAdView")
            return containerView
        }

        let adManager = CollapsibleBannerAdManager(adUnitID: adUnitID, rootViewController: rootVC)
        adManager.delegate = context.coordinator
        adManager.attachBanner(to: containerView)
        adManager.loadAd()

        context.coordinator.adManager = adManager
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No need to update anything
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, CollapsibleBannerAdDelegate {
        var adManager: CollapsibleBannerAdManager?

        func adDidReceive() {
            DDLogInfo("SwiftUI: Ad loaded successfully")
        }

        func adDidFailToLoad(error: Error) {
            DDLogError("SwiftUI: Failed to load ad: \(error.localizedDescription)")
        }

        func adDidPresent() {
            DDLogDebug("SwiftUI: Ad did present full screen")
        }

        func adDidDismiss() {
            DDLogVerbose("SwiftUI: Ad did dismiss full screen")
        }
    }
}



//
//  CollapsibleBannerAdManager.swift
//  YourApp
//
//  Created by Muhammad Umair on 15/07/2025.
//

import UIKit
import GoogleMobileAds
import CocoaLumberjack

protocol CollapsibleBannerAdDelegate: AnyObject {
    func adDidReceive()
    func adDidFailToLoad(error: Error)
    func adDidPresent()
    func adDidDismiss()
}

final class CollapsibleBannerAdManager: NSObject {

    // MARK: - Properties

    private var bannerView: BannerView?
    weak var delegate: CollapsibleBannerAdDelegate?
    private weak var rootViewController: UIViewController?
    private let adUnitID: String

    // MARK: - Init

    init(adUnitID: String, rootViewController: UIViewController) {
        self.adUnitID = adUnitID
        self.rootViewController = rootViewController
        super.init()
        setupBannerView()
    }

    // MARK: - Setup

    private func setupBannerView() {
        let banner = BannerView(adSize: AdSizeFluid)
        banner.adUnitID = adUnitID
        banner.rootViewController = rootViewController
        banner.delegate = self
        self.bannerView = banner

        DDLogVerbose("CollapsibleBannerAdManager initialized with adUnitID: \(adUnitID)")
    }

    // MARK: - Public

    func loadAd() {
        guard let bannerView = bannerView else {
            DDLogError("GAMBannerView is nil — cannot load ad")
            return
        }

        let request = Request()
        bannerView.load(request)
        DDLogInfo("Collapsible banner ad request sent")
    }

    func attachBanner(to containerView: UIView) {
        guard let bannerView = bannerView else {
            DDLogError("Cannot attach: GAMBannerView is nil")
            return
        }

        containerView.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bannerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        DDLogDebug("Banner attached to view hierarchy")
    }

    func getBannerView() -> BannerView? {
        return bannerView
    }
}

// MARK: - GADBannerViewDelegate

extension CollapsibleBannerAdManager: BannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        DDLogInfo("Banner loaded successfully")
        delegate?.adDidReceive()
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        DDLogError("Banner failed to load: \(error.localizedDescription)")
        delegate?.adDidFailToLoad(error: error)
    }

    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        DDLogDebug("Banner will present full screen content")
        delegate?.adDidPresent()
    }

    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        DDLogVerbose("Banner dismissed full screen content")
        delegate?.adDidDismiss()
    }
}

