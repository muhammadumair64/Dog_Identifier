//
//  myExtentions.swift
//  Dog-ios
//
//  Created by Umair Rajput on 11/18/24.
//

import Foundation
import SwiftUI
import UIKit
import Combine

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: Double
        switch hex.count {
        case 6: // RGB (no alpha)
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0,
                1.0
            )
        case 8: // ARGB
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0,
                Double((int >> 24) & 0xFF) / 255.0
            )
        default:
            (r, g, b, a) = (1, 1, 1, 1) // Default to white
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIImage {
    func fixOrientation() -> UIImage {
        guard self.imageOrientation != .up else {
            return self // Image is already in correct orientation
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: self.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

extension Int64 {
    func formattedDate() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(self) / 1000) // Convert from milliseconds
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, h:mm a" // Example: "Feb 26, 3:45 PM"
        formatter.locale = Locale(identifier: "en_US") // Ensures AM/PM format is correct
        formatter.timeZone = TimeZone.current // Adjusts to user's time zone
        return formatter.string(from: date)
    }
}

extension String {
    func htmlToString(size: Int) -> AttributedString {
        guard let data = self.data(using: .utf8) else {
            return AttributedString(self)
        }

        // Create an NSAttributedString from HTML data
        guard let attributedString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else {
            return AttributedString(self)
        }

        // Convert to AttributedString for SwiftUI
        var attrString = AttributedString(attributedString)

        // Apply global font size to all text
        attrString.font = .system(size: CGFloat(size))

        // Prepare an array to hold ranges for bold text
        let nsRange = NSRange(location: 0, length: attributedString.length)
        let fullString = attributedString.string
        var boldRanges: [Range<AttributedString.Index>] = []

        // Detect bold ranges
        attributedString.enumerateAttributes(in: nsRange, options: []) { attributes, range, _ in
            if let font = attributes[.font] as? UIFont,
               font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                // Convert NSRange to Swift Range
                if let stringRange = Range(range, in: fullString),
                   let attrRange = stringRange.range(in: attrString) {
                    boldRanges.append(attrRange)
                }
            }
        }

        // Apply bold style after collecting ranges
        for range in boldRanges {
            attrString[range].font = .system(size: CGFloat(size), weight: .bold)
        }

        return attrString
    }
}

// Helper extension to convert Range<String.Index> to Range<AttributedString.Index>
extension Range where Bound == String.Index {
    func range(in attributedString: AttributedString) -> Range<AttributedString.Index>? {
        let lowerBound = AttributedString.Index(self.lowerBound, within: attributedString)
        let upperBound = AttributedString.Index(self.upperBound, within: attributedString)
        
        if let lowerBound = lowerBound, let upperBound = upperBound {
            return lowerBound..<upperBound
        }
        return nil
    }
}

import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Remove hash if present
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }

        var rgba: UInt64 = 0
        guard Scanner(string: hexFormatted).scanHexInt64(&rgba) else { return nil }

        switch hexFormatted.count {
        case 8: // AARRGGBB
            let a = CGFloat((rgba & 0xFF000000) >> 24) / 255
            let r = CGFloat((rgba & 0x00FF0000) >> 16) / 255
            let g = CGFloat((rgba & 0x0000FF00) >> 8) / 255
            let b = CGFloat(rgba & 0x000000FF) / 255
            self.init(red: r, green: g, blue: b, alpha: a)

        case 6: // RRGGBB
            let r = CGFloat((rgba & 0xFF0000) >> 16) / 255
            let g = CGFloat((rgba & 0x00FF00) >> 8) / 255
            let b = CGFloat(rgba & 0x0000FF) / 255
            self.init(red: r, green: g, blue: b, alpha: 1.0)

        default:
            return nil
        }
    }
}


extension Notification.Name {
    static let newPostsSaved = Notification.Name("newPostsSaved")
}


final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    var keyboardWillShowNotification = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    var keyboardWillHideNotification = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

    init() {
        keyboardWillShowNotification.map { notification in
            CGFloat((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0)
        }
        .assign(to: \.currentHeight, on: self)
        .store(in: &cancellableSet)

        keyboardWillHideNotification.map { _ in
            CGFloat(0)
        }
        .assign(to: \.currentHeight, on: self)
        .store(in: &cancellableSet)
    }

    private var cancellableSet: Set<AnyCancellable> = []
}

struct KeyboardAdaptive: ViewModifier {
    @ObservedObject private var keyboard = KeyboardResponder()

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboard.currentHeight)
            .animation(.easeOut(duration: 0.16))
    }
}

extension UIApplication {
    
    var keyWindow: UIWindow? {
        // Get connected scenes
        return self.connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
    func getRootViewController() -> UIViewController? {
            guard let rootViewController = self.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
                    return nil
            }
            return rootViewController
        }
    
}

class DeviceUtils {
    
    /// Check if the device has a notch (iPhone X series and newer)
    static func hasNotch() -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return false
        }
        
        // Find the key window of the window scene
        guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return false
        }

        // Use the safeAreaInsets of the key window to determine if there's a notch
        let safeAreaInsets = window.safeAreaInsets
        return safeAreaInsets.top > 20 // A top inset greater than 20 points generally means a notch
    }
    /// Check if the device has a Dynamic Island (iPhone 14 Pro, Pro Max, and newer)
        static func hasDynamicIsland() -> Bool {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return false
            }
            
            guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                return false
            }

            // Devices with Dynamic Island generally have a larger top safe area inset (e.g., ~54 points)
            let safeAreaInsets = window.safeAreaInsets
            return safeAreaInsets.top > 50 // Customize the threshold based on observed behavior
        }
        
        /// Get top padding based on device type
        static func topPadding() -> CGFloat {
            if hasDynamicIsland() {
                return 40 // Larger padding for Dynamic Island
            } else {
                return 30 // Minimal padding for devices without a notch
            }
        }
}


