//
//  ShareSheet.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 01/05/2025.
//


import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
