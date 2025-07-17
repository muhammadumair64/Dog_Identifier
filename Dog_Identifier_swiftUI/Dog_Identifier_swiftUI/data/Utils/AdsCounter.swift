//
//  AdsCounter.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 06/02/2025.
//


import Foundation

final class AdsCounter {
    private static var adsCounter = 0
    private static var scanningAdCounter = 0
    private static var playAdsCounter = 0
    public static var isFromSplash = false
    
    static var ratingCounter = 0
     static var showProCounter = 3
    static var isShowOpenAd  =  true

    /// Determines whether to show a play ad based on the play ads counter
    static func shouldShowPlayAd() -> Bool {
        playAdsCounter += 1
        return playAdsCounter % 2 == 0
    }

    /// Determines whether to show an ad based on the ads counter
    static func shouldShowAd() -> Bool {
        adsCounter += 1
        return adsCounter % 2 == 0
    }
    static func shouldShowScanningAd() -> Bool {
        scanningAdCounter += 1
        return scanningAdCounter % 2 == 0
    }

    /// Determines whether to show a rating prompt based on the rating counter
    static func shouldShowRating() -> Bool {
        ratingCounter += 1
        return ratingCounter % 6 == 0
    }

    /// Determines whether to show a pro feature prompt based on the pro counter
    static func shouldShowPro() -> Bool {
        showProCounter += 1
        return showProCounter % 4 == 0
    }
}
