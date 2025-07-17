//
//  ExploreItemDataClass.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 16/12/2024.
//

import Foundation

struct ExploreItemDataClass: Codable ,Identifiable{
    var id: Int
    let image: String
    let title: String
    let subtitle: String
    let colorString : String
}
