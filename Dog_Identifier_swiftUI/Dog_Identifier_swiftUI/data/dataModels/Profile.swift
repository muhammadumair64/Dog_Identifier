//
//  Profile.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 06/01/2025.
//


import SwiftUI

class Profile {
    var profileImageName: String
    var profileName: String
    var profileLocation: String
    var postCount: Int
    var likeCount: Int
    var followerCount: Int
    var followingCount: Int
    var postsTabTitle: String
    var collectionTabTitle: String
    var collectionItems: [CollectionItem]
    
    init(profileImageName: String, profileName: String, profileLocation: String,
         postCount: Int, likeCount: Int, followerCount: Int, followingCount: Int,
         postsTabTitle: String, collectionTabTitle: String, collectionItems: [CollectionItem]) {
        self.profileImageName = profileImageName
        self.profileName = profileName
        self.profileLocation = profileLocation
        self.postCount = postCount
        self.likeCount = likeCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.postsTabTitle = postsTabTitle
        self.collectionTabTitle = collectionTabTitle
        self.collectionItems = collectionItems
    }
}
