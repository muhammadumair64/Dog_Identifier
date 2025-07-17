//
//  LoadingDialogView.swift
//  Insect-detector-ios
//
//  Created by Umair Rajput on 2/2/25.
//

import SwiftUI

struct LoadingDialogView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text("Ad Loading...")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.top, 8)
            }
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadius(10)
        }
    }
}
