//
//  ColorHelper.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 10/12/2024.
//

import Foundation
import SwiftUICore

enum ColorHelper {
    case primary
    case primaryBlue
    case secondary
    case darkText
    case lightRed
    case lightText
    case lightIndicator
    case grayBG
    
    var color: Color {
        switch self {
        case .primary:
            return Color(hex: "#FFB618")
        case .secondary:
            return Color(hex: "#FFFFFF")
        case .darkText:
            return Color(hex: "#161816")
        case .lightRed:
            return Color(hex: "#FC4444")
        case .lightIndicator:
            return Color(hex: "#CCDEE4")
        case .grayBG:
            return Color(hex: "#EAEAEA")
        case .lightText:
            return Color(hex: "#727272")
        case .primaryBlue:
            return Color(hex: "#2C8BE7")
        }
    }
}

