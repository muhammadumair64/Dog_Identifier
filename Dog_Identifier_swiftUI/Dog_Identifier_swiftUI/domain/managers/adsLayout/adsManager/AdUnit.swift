//
//  AdUnit.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 04/02/2025.
//


import AdSupport
import AppTrackingTransparency
import Foundation

enum AdUnit: String {
    case homeRewarded
    case interstitial
    case homeBanner
    case openAd
    case nativeNoMedia
    case nativeMedia
    case splashInter

    // You should return your ad unit IDs here
    var unitId: String {
        switch self {
       #if DEBUG
            // Admob Test IDs
        case .homeRewarded: return "ca-app-pub-3940256099942544/1712485313"
        case .interstitial: return "ca-app-pub-3940256099942544/4411468910"
        case .homeBanner: return "ca-app-pub-3940256099942544/2934735716"
        case .openAd: return "ca-app-pub-3940256099942544/5575463023"
        case .nativeMedia : return "ca-app-pub-3940256099942544/1044960115"
        case .nativeNoMedia : return "ca-app-pub-3940256099942544/3986624511"
        case .splashInter: return "ca-app-pub-3940256099942544/4411468910"
        #else
            // Admob Release IDs
        case .homeRewarded: return rewardedID
        case .interstitial: return interstitialID
        case .homeBanner: return bannerID
        case .openAd: return openAdID
        case .nativeMedia : return nativeWithMediaID
        case .nativeNoMedia : return nativeNoMediaID
        case .splashInter: return splashInterID
        #endif
       
        }
    }
}

// Admob Release IDs (You MUST replace these with your actual IDs)
let bannerID = "ca-app-pub-9262123212469470/8022449884" // Replace with your Banner Ad Unit ID
let interstitialID = "ca-app-pub-9262123212469470/2916019901" // Replace with your Interstitial Ad Unit ID
let rewardedID = "ca-app-pub-9262123212469470/5722146641" // Replace with your Rewarded Ad Unit ID
let openAdID = "ca-app-pub-9262123212469470/6246333782" // Replace with your App Open Ad Unit ID
let nativeNoMediaID = "ca-app-pub-9262123212469470/9469819969"
let nativeWithMediaID = "ca-app-pub-9262123212469470/3095983309"
let splashInterID = "ca-app-pub-9262123212469470/5884269490"
