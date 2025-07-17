//
//  Dog_Identifier_swiftUIApp.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 17/04/2025.
//


import SwiftUI
import SwiftData

@main
struct Dog_Identifier_swiftUIApp: App {


    @StateObject private var navigationManager = NavigationManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationHandler(navigationManager: navigationManager)
                .preferredColorScheme(.light)
                .onAppear{
                }
        }
    }
}
