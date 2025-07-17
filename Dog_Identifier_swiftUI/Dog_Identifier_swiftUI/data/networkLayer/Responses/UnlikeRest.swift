//
//  UnlikeRest.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 21/01/2025.
//


import Foundation

struct UnlikeRest: Codable {
    var likeId: Int
    var message: String
    var unLikeSuccessful: Bool
    var userId: Int

    enum CodingKeys: String, CodingKey {
        case likeId = "likeId"
        case message = "message"
        case unLikeSuccessful = "unLikeSuccessful"
        case userId = "userId"
    }
}
