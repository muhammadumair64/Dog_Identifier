//
//  ToastView.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 06/02/2025.
//


import SwiftUI

struct ToastView: View {
    var message: String
    var duration: TimeInterval = 2.0 // Default duration for toast visibility
    
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            Spacer()
            if isVisible {
                Text(message)
                    .font(.system(size: 14))
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .transition(.opacity.animation(.easeInOut))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isVisible = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .padding(.bottom, 50) // Adjust bottom padding for the toast position
    }
}
