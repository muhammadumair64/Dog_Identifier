////
////  Dog.swift
////  Dog_Identifier_swiftUI
////
////  Created by Mac Mini on 28/04/2025.
//
//import Foundation
//
//struct Dog: Codable, Identifiable {
//    let id: Int
//    let breedName: String
//    let breedLabel: String?
//    let otherNames: String
//    let popularity: String?
//    let origin: String
//    let breedGroup: String
//    let size: String
//    let type: String
//    let lifeSpan: String?
//    let temperament: String?
//    let height: String?
//    let weight: String?
//    let colors: String?
//    let litterSize: String?
//    let puppyPrice: String?
//    let puppyNames: [PuppyName]?
//    let dogBreedDetailList: [DogBreedDetailList]?
//    let characteristics: [String]?
//}
//
//struct PuppyName: Codable {
//    let id: Int
//    let rank: String
//    let maleName: String
//    let femaleName: String
//    let breedId: Int
//}
//
//struct DogBreedDetailList: Codable {
//    let id: Int
//    let title: String
//    let detail: String
//    let breedId: Int
//}


// MARK: - Data Models
struct PuppyName: Identifiable, Codable {
    let id: Int
    let rank: String
    let maleName: String
    let femaleName: String
    let breedId: Int
}

struct DogBreedDetail: Identifiable, Codable {
    let id: Int
    let title: String
    let detail: String
    let breedId: Int
}

struct Characteristic: Identifiable, Codable {
    let id: Int
    let breedId: Int
    let charactisitcName: String
    let rating: String
    let description: String
}

struct Dog: Identifiable, Codable {
    let id: Int
    let breedName: String
    let breedLabel: String
    let otherNames: String
    let popularity: String
    let origin: String
    let breedGroup: String
    let size: String
    let type: String
    let lifeSpan: String
    let temperament: String
    let height: String
    let weight: String
    let colors: String
    let litterSize: String
    let puppyPrice: String
    let puppyNames: [PuppyName]
    let dogBreedDetailList: [DogBreedDetail]
    let characteristics: [Characteristic]
}
