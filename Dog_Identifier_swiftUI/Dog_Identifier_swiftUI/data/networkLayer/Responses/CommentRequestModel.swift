//
//  CommentRequestModel.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 21/01/2025.
//


import Foundation

struct CommentRequestModel: Codable {
    let postId: Int
    let userId: Int
    let commentStr: String
    
    init(postId: Int, userId: Int, commentStr: String) {
        self.postId = postId
        self.userId = userId
        self.commentStr = commentStr
    }
}
