//
//  NavigationBarView.swift
//  Insect-detector-ios
//
//  Created by Umair Rajput on 1/28/25.
//
import SwiftUI

// MARK: - Navigation Bar View
struct NavigationBarView: View {
    @ObservedObject var navigationManager: NavigationManager
    let title: String
    
    var body: some View {
        HStack {
            HStack {
                Button(action: {
                    navigationManager.pop()
                }) {
                    Image("backBtn")
                        .foregroundColor(.orange)
                        .font(.title2)
                }
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .padding(.leading,20)
                Spacer()
            }
            Spacer()
//            Button(action: {
//                // Handle share action
//            }) {
//                Image(systemName: "square.and.arrow.up")
//                    .foregroundColor(.orange)
//                    .font(.title2)
//            }
        }
        .padding()
    
    }
}
