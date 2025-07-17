//
//  Insect.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 28/01/2025.
//


import Foundation

// Data model for Butterfly, Ants, Bees, Beetles, Spiders (Can be used for all Insects)
struct Insect: Identifiable, Decodable {
    let id: String
    let Title: String
    let image: String
    let insectDescription: String
    let diet: String
    let habitat: String
    let scientificName: String
    let lifespan: String
    let behavior: String
}

// Generic Insect Response for Decoding
struct InsectsResponse: Decodable {
    let Insect: [Insect]
}
