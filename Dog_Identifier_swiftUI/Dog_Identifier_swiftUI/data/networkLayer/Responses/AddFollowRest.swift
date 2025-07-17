//
//  AddFollowRest.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 29/01/2025.
//


import Foundation

struct AddFollowRest: Decodable {
    let followedUserId: Int
    let followerUser: FollowerUser
    let id: Int
}

struct FollowerUser: Decodable {
    let address: String?
    let bio: String?
    let city: String?
    let country: String?
    let createdAt: TimeInterval
    let email: String?
    let imageUrl: String?
    let lat: Double?
    let lng: Double?
    let name: String?
    let notificationToken: String?
    let number: String?
    let uid: String?
    let userId: Int?
    let followedUserId: Int?
}
