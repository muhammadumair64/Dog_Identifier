//
//  NativeAdManager.swift
//  NativeAdvancedExample
//
//  Created by Mac Mini on 29/05/2025.
//

import SwiftUI
import GoogleMobileAds
import Combine
import CocoaLumberjack

// MARK: - Manager

final class NativeAdManager: NSObject, ObservableObject {

    static let shared = NativeAdManager()
    
    @Published var nativeAd: NativeAd?
    @Published var isLoaded: Bool = false
    @Published var loadError: String?
    
    private var adLoader: AdLoader?
    private var adUnitID: String = ""
    private var layout: NativeAdLayout = .medium
    private weak var rootViewController: UIViewController?
    
    private override init() {
        super.init()
    }

    @MainActor
    func load(adUnitID: String, layout: NativeAdLayout, rootVC: UIViewController) async {
        self.adUnitID = adUnitID
        self.layout = layout
        self.rootViewController = rootVC
        self.isLoaded = false
        self.nativeAd = nil
        self.loadError = nil

        let request = Request()
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootVC,
            adTypes: [.native],
            options: nil
        )
        adLoader?.delegate = self
        adLoader?.load(request)
        DDLogInfo("📡 Loading native ad with unit ID: \(adUnitID)")
    }
}

// MARK: - AdLoader Delegate

extension NativeAdManager: @preconcurrency NativeAdLoaderDelegate {
    @MainActor
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DDLogInfo("✅ Native ad loaded.")
        self.nativeAd = nativeAd
        self.isLoaded = true
        nativeAd.delegate = self
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DDLogError("❌ Native ad failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.loadError = error.localizedDescription
            self.isLoaded = false
        }
    }
}

// MARK: - NativeAd Delegate

extension NativeAdManager: NativeAdDelegate {
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        DDLogDebug("🖱️ Native ad clicked.")
    }

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        DDLogDebug("👁️ Native ad impression recorded.")
    }
}

// MARK: - SwiftUI Ad View (UIViewRepresentable)

struct NativeAdContainerView: UIViewRepresentable {
    
    let nativeAd: NativeAd
    let layout: NativeAdLayout

    func makeUIView(context: Context) -> NativeAdView {
        guard let nibObjects = Bundle.main.loadNibNamed(layout.rawValue, owner: nil, options: nil),
              let adView = nibObjects.first as? NativeAdView else {
            assertionFailure("❌ Could not load layout: \(layout.rawValue)")
            return NativeAdView()
        }

        adView.nativeAd = nativeAd

        // ✅ Style the ad view container itself
        adView.layer.cornerRadius = 12
        adView.layer.masksToBounds = true
        adView.backgroundColor = UIColor(hex: "#FDFDFD") // or use any UIColor/HexColor here
        adView.layer.borderWidth = 1
        adView.layer.borderColor = UIColor.lightGray.cgColor
        
        adView.layer.borderColor = UIColor(hex: "#B0B0B0")?.cgColor
        // ✅ Headline
        (adView.headlineView as? UILabel)?.text = nativeAd.headline

        // ✅ Media
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        adView.mediaView?.layer.cornerRadius = 10
        adView.mediaView?.clipsToBounds = true

        // ✅ Body
        if let body = nativeAd.body {
            (adView.bodyView as? UILabel)?.text = body
            adView.bodyView?.isHidden = false
        } else {
            adView.bodyView?.isHidden = true
        }

        // ✅ CTA
        if let callToAction = nativeAd.callToAction {
            let button = adView.callToActionView as? UIButton
            button?.setTitle(callToAction, for: .normal)
            button?.layer.cornerRadius = 10
            button?.clipsToBounds = true
            adView.callToActionView?.isHidden = false
        } else {
            adView.callToActionView?.isHidden = true
        }

        // ✅ Icon
        if let iconImage = nativeAd.icon?.image {
            let imageView = adView.iconView as? UIImageView
            imageView?.image = iconImage
            imageView?.layer.cornerRadius = 8
            imageView?.clipsToBounds = true
            adView.iconView?.isHidden = false
        } else {
            adView.iconView?.isHidden = true
        }

        // ✅ Star Rating
        if let rating = nativeAd.starRating {
            (adView.starRatingView as? UIImageView)?.image = starImage(for: rating)
            adView.starRatingView?.isHidden = false
        } else {
            adView.starRatingView?.isHidden = true
        }

        // ✅ Store
        if let store = nativeAd.store {
            (adView.storeView as? UILabel)?.text = store
            adView.storeView?.isHidden = false
        } else {
            adView.storeView?.isHidden = true
        }

        // ✅ Price
        if let price = nativeAd.price {
            (adView.priceView as? UILabel)?.text = price
            adView.priceView?.isHidden = false
        } else {
            adView.priceView?.isHidden = true
        }

        // ✅ Advertiser
        if let advertiser = nativeAd.advertiser {
            (adView.advertiserView as? UILabel)?.text = advertiser
            adView.advertiserView?.isHidden = false
        } else {
            adView.advertiserView?.isHidden = true
        }

        return adView
    }


    func updateUIView(_ uiView: NativeAdView, context: Context) {
        // No updates needed for now
    }

    private func starImage(for rating: NSDecimalNumber?) -> UIImage? {
        guard let rating = rating?.doubleValue else { return nil }
        switch rating {
        case 5.0: return UIImage(named: "stars_5")
        case 4.5...4.9: return UIImage(named: "stars_4_5")
        case 4.0...4.4: return UIImage(named: "stars_4")
        case 3.5...3.9: return UIImage(named: "stars_3_5")
        default: return nil
        }
    }
}

struct AdSectionView: View {
    @StateObject private var adManager = NativeAdManager.shared
    var adUnitID: String
    var layout: NativeAdLayout
    var rootViewController: UIViewController

    // Retrieve once and keep it in memory-safe way
    private var isProUser: Bool {
        UserDefaultManager.shared.get(forKey: .isPremiumUser) ?? false
    }

    var body: some View {
        VStack {
            if isProUser {
                EmptyView() // or show nothing at all
            } else if let ad = adManager.nativeAd {
                NativeAdContainerView(nativeAd: ad, layout: layout)
                    .frame(height: layout == .medium ? 300 : 165)
            } else if let error = adManager.loadError {
                EmptyView()
            } else {
                ProgressView()
            }
        }
        .task {
            guard !isProUser else {
                DDLogInfo("🛑 Skipping ad load for premium user")
                return
            }
            await adManager.load(adUnitID: adUnitID, layout: layout, rootVC: rootViewController)
        }
    }
}

enum NativeAdLayout: String {
    case medium = "NativeAdViewLarge"
    case small = "NativeAdView"
}

extension UIApplication {
    var rootVC: UIViewController {
        // Safely unwrap keyWindow’s rootViewController
        guard let root = self.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: \.isKeyWindow)?
            .rootViewController else {
                fatalError("Unable to find rootViewController")
            }
        return root
    }
}


/// AD Usage Example

//AdSectionView(
//      adUnitID: "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx", // <-- your ad unit ID
//      layout: .medium,
//      rootViewController: UIApplication.shared.rootVC
//  )
//  .padding()
