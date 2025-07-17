//
//  LikeRequestModel.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 20/01/2025.
//


import Foundation

// LikeRequestModel - Request Model
struct LikeRequestModel: Codable {
    let postId: Int
    let userId: Int
}

// UserLikesDto - Response Model
struct UserLikesDto: Codable {
    let postLikes: [UserLike]
    
    struct UserLike: Codable {
        let userName:String?
        let imageUrl:String?
        let userId: Int
        let postId: Int
        let createdAt: Int64?
        let likeId: Int
        let userBio: String?
    }
}
