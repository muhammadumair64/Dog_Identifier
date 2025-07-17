//
//  MODEL.swift
//  Planty_Identify
//
//  Created by iobits Technologies on 04/10/2024.
//

import Foundation
import AuthenticationServices

// MARK: - Welcome
struct PostBaseModel: Codable {
    var posts: [Post]
    let totalPages, totalRecords, pageNumber: Int?
}



// MARK: - Post
struct Post: Codable {
    let userName, title: String
    let location : String?
    let description :String?
    let userID: Int
    let imageURL: String?
    var postID, watcherCount, commentCount, likeCount: Int
    let userImage: String
    let userBio: String?
    let createdAt: Int
    let category: String?

    enum CodingKeys: String, CodingKey {
        case location, userName, description, title
        case userID = "userId"
        case imageURL = "imageUrl"
        case postID = "postId"
        case watcherCount, commentCount, likeCount, userImage, userBio, createdAt, category
    }
}


//MARK: - USER MODEL

struct AppleUser :Codable{
    let id:String
    let firstName:String
    let lastName:String
    let email:String
    
    
    init(credentials:ASAuthorizationAppleIDCredential){
        self.id = credentials.user
        self.firstName = credentials.fullName?.givenName ?? ""
        self.lastName = credentials.fullName?.familyName ?? ""
        self.email = credentials.email ?? ""
    }
}

// MARK: - Comment Model

// MARK: - Welcome
struct CommentsResponse: Codable {
    let postComments: [PostComment]
}

// MARK: - PostComment
struct PostComment: Codable {
    let postID, userID: Int?
    let userName, commentStr: String?
    let commentID: Int?
    let userBio: String?
    let createdAt: Int?
    let userImageURL: String?

    enum CodingKeys: String, CodingKey {
        case postID = "postId"
        case userID = "userId"
        case userName, commentStr
        case commentID = "commentId"
        case userBio, createdAt
        case userImageURL = "userImageUrl"
    }
}

class AddedComment: Codable {
    let commentID, postID: Int
    let commentStr: String
    let dateTime: Int
    let user: myUser

    enum CodingKeys: String, CodingKey {
        case commentID = "commentId"
        case postID = "postId"
        case commentStr, dateTime, user
    }

    init(commentID: Int, postID: Int, commentStr: String, dateTime: Int, user: myUser) {
        self.commentID = commentID
        self.postID = postID
        self.commentStr = commentStr
        self.dateTime = dateTime
        self.user = user
    }
}


class PostLike: Codable {
    let postLikes: [PostLikeElement]

    init(postLikes: [PostLikeElement]) {
        self.postLikes = postLikes
    }
}

// MARK: - PostLikeElement
class PostLikeElement: Codable {
    let postID, userID: Int
    let imageURL: String
    var userName, userBio: String
    let likeID, createdAt: Int

    enum CodingKeys: String, CodingKey {
        case postID = "postId"
        case userID = "userId"
        case imageURL = "imageUrl"
        case userName, userBio
        case likeID = "likeId"
        case createdAt
    }

    init(postID: Int, userID: Int, imageURL: String, userName: String, userBio: String, likeID: Int, createdAt: Int) {
        self.postID = postID
        self.userID = userID
        self.imageURL = imageURL
        self.userName = userName
        self.userBio = userBio
        self.likeID = likeID
        self.createdAt = createdAt
    }
}


struct PostByID: Codable {
    let location, title: String
    let postID, userID: Int
    let imageURL: String
    let watcherCount: Int?
    let postByIDDescription, userName: String
    let commentCount, likeCount: Int
    let userBio: String
    let createdAt: Int
    let category: String
    let userImage: String

    enum CodingKeys: String, CodingKey {
        case location, title
        case postID = "postId"
        case userID = "userId"
        case imageURL = "imageUrl"
        case watcherCount
        case postByIDDescription = "description"
        case userName, commentCount, likeCount, userBio, createdAt, category, userImage
    }
}


class Posts:Codable{
    @objc dynamic var userName: String =  "", postDescription: String = "", title: String = ""
    @objc dynamic var userID:Int=0
    @objc dynamic var postID: Int=0
    @objc dynamic var imageURL: String=""
    @objc dynamic var createdAt: Int=0
    @objc dynamic var commentCount: Int=0
    @objc dynamic var likeCount: Int=0
    @objc dynamic var watcherCount:Int=0
    @objc dynamic var userImage: String=""
    @objc dynamic var userBio: String=""
    @objc dynamic var category: String=""
    @objc dynamic var location: String=""
    @objc dynamic var isLikedByMe : Bool = false
    var isBookmarked : Bool = false
    
    enum CodingKeys: String, CodingKey {
        case userName
        case postDescription = "description"
        case title
        case userID = "userId"
        case postID = "postId"
        case imageURL = "imageUrl"
        case watcherCount, createdAt, commentCount, likeCount, userImage, userBio, category, location
    }
    
    
    
    
    func getPostObj(postById:PostByID){
        self.userName = postById.userName
        self.postDescription = postById.userName
        self.title = postById.title
        self.userID = postById.userID
        self.postID = postById.postID
        self.imageURL = postById.imageURL
        self.watcherCount = postById.watcherCount ?? 0
        self.createdAt = postById.createdAt
        self.commentCount = postById.commentCount
        self.likeCount = postById.likeCount
        self.userImage = postById.userImage
        self.userBio = postById.userBio
        self.category = postById.category
        self.location = postById.location
    }
    
}

class PostLiked:Codable {
    @objc dynamic var postID, likeID, userID: Int
    
    enum CodingKeys: String, CodingKey {
        case postID = "postId"
        case likeID = "likeId"
        case userID = "userId"
    }
    
    
    
    init(postID: Int, likeID: Int, userID: Int) {
        self.postID = postID
        self.likeID = likeID
        self.userID = userID
    }
}

//MARK: - CREATE POST
struct PostCreated: Codable {
    let postID: Int
    let uid, title, postCreatedDescription, imageURL: String
    let location: String
    let lat, lng, createdAt: Int
    let updatedAt, category: String
    let userDto: String?
    let watcherCount: Int

    enum CodingKeys: String, CodingKey {
        case postID = "postId"
        case uid, title
        case postCreatedDescription = "description"
        case imageURL = "imageUrl"
        case location, lat, lng, createdAt, updatedAt, category, userDto, watcherCount
    }
}



