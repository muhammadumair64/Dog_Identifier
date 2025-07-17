//
//  CustomPagingIndicator.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 10/12/2024.
//


import SwiftUI

struct CustomPagingIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalPages, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: index == currentPage ? 25 : 7, height: 7) // Increase width for selected dot
                    .foregroundColor(index == currentPage ? ColorHelper.primary.color : ColorHelper.lightIndicator.color)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)  // Scale the selected dot
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .padding(.horizontal)
    }
}

