//
//  FollowerRest.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 10/01/2025.
//


import Foundation

struct FollowerRest: Codable {
    let followers: [Follower]

    struct Follower: Codable {
        let followedUserId: Int
        let followerUser: FollowerUser
        let id: Int

        struct FollowerUser: Codable {
            let userId: Int
            let address: String?
            let bio: String?
            let city: String?
            let country: String?
            let createdAt: Int?
            let email: String
            let imageUrl: String?
            let lat: Double?
            let lng: Double?
            let name: String
            let notificationToken: String
            let number: String?
            let uid: String
        }
    }
}

struct FollowingRest: Codable {
    let following: [Following]

    struct Following: Codable {
        let followerUserId: Int
        let followingUser: FollowingUser
        let id: Int

        struct FollowingUser: Codable {
            let userId: Int
            let address: String?
            let bio: String?
            let city: String?
            let country: String?
            let createdAt: Int?
            let email: String
            let imageUrl: String?
            let lat: Double?
            let lng: Double?
            let name: String
            let notificationToken: String
            let number: String?
            let uid: String
        }
    }
}
