//
//  PostCommentsResponse.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 20/01/2025.
//


import Foundation

class PostCommentsResponse: Decodable {
    var comments: [Comment]

    enum CodingKeys: String, CodingKey {
        case comments = "postComments"
    }


    class Comment: Decodable {
        var commentId: Int
        var commentText: String
        var createdAt: Int64
        var postId: Int
        var userId: Int
        var userImageUrl: String
        var userBio: String
        var userName: String

        enum CodingKeys: String, CodingKey {
            case commentId
            case commentText = "commentStr"
            case createdAt
            case postId
            case userId
            case userImageUrl
            case userBio
            case userName
        }
    }
}
