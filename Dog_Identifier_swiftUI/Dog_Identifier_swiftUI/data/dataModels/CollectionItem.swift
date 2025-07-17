//
//  CollectionItem.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 06/01/2025.
//
import SwiftUI

class CollectionItem: Identifiable {
    var id: UUID
    var imageName: String
    var title: String
    var date: String
    
    init(imageName: String, title: String, date: String) {
        self.id = UUID()
        self.imageName = imageName
        self.title = title
        self.date = date
    }
}
