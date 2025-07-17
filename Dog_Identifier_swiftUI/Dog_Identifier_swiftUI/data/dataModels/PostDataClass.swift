//  PostDataClass.swift
//  Insect-detector-ios
//
//  Created by Umair Rajput on 12/14/24.
//

struct PostDataClass: Codable ,Identifiable{
    var id: Int
    let image: String
    let profilePic:String
    let username:String
    let date:String
    let description: String
    let likes:String
    let comments:String
    let shares:String
}
