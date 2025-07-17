//
//  AppSideMenuViewModel.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 30/01/2025.
//


//
//  ShareAppViewModel.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 30/01/2025.
//


import Foundation
import UIKit
import Combine
import CocoaLumberjack
import StoreKit

class AppSideMenuViewModel: ObservableObject {
    
    func shareApp(from viewController: UIViewController) {
        let appStoreURL = "https://apps.apple.com/us/app/butterfly-identifier/id6475772883"
        let shareMessage = "Check out this amazing app! Download it here: \(appStoreURL)"
        
        let activityViewController = UIActivityViewController(activityItems: [shareMessage], applicationActivities: nil)
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                                  y: viewController.view.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        DDLogInfo("Presenting share sheet for the app.")
        
        viewController.present(activityViewController, animated: true) {
            DDLogDebug("Share sheet presented successfully.")
        }
    }
   

    func showPrivacyPolicy(from viewController: UIViewController , urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    DDLogInfo("Privacy policy URL successfully opened.")
                } else {
                    DDLogError("Failed to open privacy policy URL.")
                }
            }
        } else {
            DDLogError("Invalid or unsupported URL: \(urlString)")
            
            // Optionally, you can show an alert if the URL is invalid
            let alert = UIAlertController(
                title: "Error",
                message: "Unable to open the privacy policy. Please try again later.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
        }
    }

    func promptForRating() {
            
          //  let activityIndicator = Constants.shared.showLoadingIndicator(self)
            
            if #available(iOS 10.3, *) {
                // Request review with a small delay to allow the loading indicator to show up
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    SKStoreReviewController.requestReview()
                    
                    // Dismiss loading indicator after requesting review
              //      Constants.shared.hideLoadingIndicator(activityIndicator)
                }
            } else {
                // Fallback for earlier iOS versions or other rating methods
                openAppStoreForRating()
                
                // Dismiss loading indicator since the rating popup won't appear automatically
           //     Constants.shared.hideLoadingIndicator(activityIndicator)
            }
        }


    func openAppStoreForRating() {
            let appID = "6475772883" // Replace this with your actual App ID
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]
    , completionHandler: nil)
            }
        }
    
    func showPolicy() {
        AdsCounter.isShowOpenAd = false
        
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            DDLogError("Failed to get the root view controller.")
            return
        }
        
     showPrivacyPolicy(from: rootVC, urlString: "https://iobitsllc.blogspot.com/2025/05/dog-identifier-ios-privacy-policy.html")
    }

    func showTerms() {
        AdsCounter.isShowOpenAd = false

        
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            DDLogError("Failed to get the root view controller.")
            return
        }
        
       showPrivacyPolicy(from: rootVC, urlString: "https://iobitsllc.blogspot.com/2025/05/dog-identifier-ios-privacy-policy.html")
    }

    
}
