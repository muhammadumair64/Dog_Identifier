//
//  CreatePostModel.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 22/01/2025.
//


import Foundation

struct CreatePostModel: Codable {
    let uid: String
    let title: String
    let description: String
    let imageUrl: String
    let location: String
    let lat: Float
    let lng: Float
    let category: String?
}

struct ResponsePostModel: Codable {
    let postId: Int
    let uid: String
    let title: String
    let description: String?
    let imageUrl: String
    let location: String?
    let lat: Double?   // Use Double for latitude
    let lng: Double?   // Use Double for longitude
    let createdAt: Int64 // Use Int64 for timestamps
    let updatedAt: String?
    let category: String?
    let userDto: String?
    let watcherCount: Int
}

