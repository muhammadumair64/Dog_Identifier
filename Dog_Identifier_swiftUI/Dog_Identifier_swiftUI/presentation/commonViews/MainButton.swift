//
//  WeatherButton.swift
//  IosFirstApp
//
//  Created by Umair Rajput   on 14/08/2024.
//
import SwiftUI

struct MainButton: View {
    var title:String
    var btnColor:Color = ColorHelper.primary.color
    var width:CGFloat
    var height:CGFloat
    var textsize:CGFloat = 22
    var radius : CGFloat = 15
    var forgroundColor = Color.white
    
    var body: some View {
        Text(title)
            .frame(width:width ,height: height)
            .foregroundColor(forgroundColor)
            .background(btnColor)
            .cornerRadius(radius)
            .font(.custom(FontHelper.bold.rawValue, size: textsize))
    }
}

