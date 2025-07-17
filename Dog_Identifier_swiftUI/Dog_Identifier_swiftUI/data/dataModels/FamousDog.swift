//
//  FamousDog.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 29/04/2025.
//
import Foundation

struct FamousDog: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String? // `nil` for "View More"
}
