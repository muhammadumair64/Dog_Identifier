//
//  CommentRest.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 21/01/2025.
//


import Foundation

struct CommentRest: Codable {
    let commentId: Int?
    let commentStr: String?
    let dateTime: Int64? // Assuming `dateTime` is a Unix timestamp
    let postId: Int?
    let user: myUser?
}
