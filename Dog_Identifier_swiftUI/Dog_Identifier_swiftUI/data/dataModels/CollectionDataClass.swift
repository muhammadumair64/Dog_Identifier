//
//  CollectionDataClass.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 03/01/2025.
//

import Foundation


struct CollectionDataClass: Codable ,Identifiable {
    var id: Int
    let image: String
    let title: String
    let description :String
}

